# Makefile for macOS Complete System Update
# Run with: make update
#
# Environment vars:
#   YES=0         Ask for confirmation before macOS updates / restore (default: YES=1, no prompts)
#   BREWFILE=...  Override Brewfile path for dump/restore

SHELL := /bin/bash

# User-agnostic setup: works whether you run this as ks, ptc, or anyone else.
# Homebrew is shared via the 'admin' group (run 'make brew-share' once).
BREW_PREFIX := $(shell command -v brew >/dev/null 2>&1 && brew --prefix || echo /opt/homebrew)
USER_NAME   := $(shell whoami)

# Non-interactive by default: nothing asks for confirmation. Use YES=0 to be asked.
YES ?= 1

# Make brew reachable even if the current user's shell profile isn't loaded
export PATH := $(BREW_PREFIX)/bin:$(PATH)

.PHONY: help update system brew brew-share brew-writable mas microsoft clean status brew-list dump restore install link macos dump-dotfiles

help:
	@echo '🚀 macOS Update Commands:'
	@echo '  make update       - Complete system update (recommended)'
	@echo '  make status       - Show what needs updating'
	@echo '  make brew         - Update Homebrew packages only (no Gatekeeper popups)'
	@echo '  make brew-share   - Share Homebrew between users (run once with sudo)'
	@echo '  make system       - Update macOS only'
	@echo '  make mas          - Update App Store apps only'
	@echo '  make microsoft    - Update Microsoft apps only'
	@echo '  make brew-list    - List all installed packages'
	@echo '  make dump         - Export all installed packages to Brewfile'
	@echo '  make restore      - Install all packages from Brewfile (new machine)'
	@echo '  make install      - Full fresh-machine setup (packages + dotfiles + macOS prefs)'
	@echo '  make link         - Symlink dotfiles from this repo into $$HOME'
	@echo '  make macos        - Apply saved macOS system preferences'
	@echo '  make dump-dotfiles- Copy current dotfiles from $$HOME into this repo'
	@echo '  make clean        - Clean up and free space'
	@echo '  make help         - Show this help message'
	@echo ''
	@echo '💡 Tips:'
	@echo '  Runs unattended by default — nothing asks for confirmation.'
	@echo '  YES=0 make restore   - Ask before restoring packages'
	@echo '  YES=0 make system    - Ask before installing macOS updates'

update:
	@echo "🔄 Running full system update..."
	@echo ""
	@$(MAKE) --no-print-directory YES=1 system
	@$(MAKE) --no-print-directory brew
	@$(MAKE) --no-print-directory mas
	@$(MAKE) --no-print-directory microsoft
	@$(MAKE) --no-print-directory clean
	@echo ""
	@echo "✅ All updates completed successfully!"
# 	@open "raycast://extensions/raycast/raycast/confetti"

status:
	@echo "📊 Current update status:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "🍺 HOMEBREW STATUS:"
	@if [ -w "$(BREW_PREFIX)" ]; then \
		echo "  ✅ $(BREW_PREFIX) is writable by $(USER_NAME)"; \
	else \
		echo "  ⚠️  $(BREW_PREFIX) is owned by $$(stat -f '%Su' "$(BREW_PREFIX)") — run 'make brew-share' once to share it"; \
	fi
	@FORMULAE=$$(brew leaves 2>/dev/null); CASKS=$$(brew list --casks 2>/dev/null); \
	echo "  📦 Total packages: $$(echo "$$FORMULAE" | grep -c .) explicitly installed formulae, $$(echo "$$CASKS" | grep -c .) casks"
	@echo "  ⬆️  Outdated packages:"
	@OUTDATED=$$(brew outdated --greedy-latest 2>/dev/null); \
	if [ -n "$$OUTDATED" ]; then \
		echo "$$OUTDATED" | sed 's/^/    /'; \
	else \
		echo "    ✓ All Homebrew packages are up to date!"; \
	fi
	@echo "  💡 'make brew' skips self-updating casks (Chrome, VS Code, Slack…) — they update themselves."
	@echo ""
	@echo "📦 APP STORE STATUS:"
	@if command -v mas > /dev/null; then \
		echo "  Installed apps: $$(mas list | wc -l | tr -d ' ')"; \
		echo "  Updates available:"; \
		OUTDATED_MAS=$$(mas outdated 2>/dev/null); \
		if [ -n "$$OUTDATED_MAS" ]; then \
			echo "$$OUTDATED_MAS" | sed 's/^/    /'; \
		else \
			echo "    ✓ All App Store apps are up to date!"; \
		fi \
	else \
		echo "  ⚠️  mas-cli not installed (run: brew install mas)"; \
	fi
	@echo ""
	@echo "🖥️  MACOS STATUS:"
	@if softwareupdate --list --all 2>&1 | grep -q "No new software available"; then \
		echo "  ✓ macOS is up to date"; \
	else \
		softwareupdate --list --all | grep -v "Software Update Tool" | grep -v "Finding available software"; \
	fi

system:
	@if softwareupdate --list --all 2>&1 | grep -q "No new software available"; then \
		echo "🖥️  macOS is up to date — skipping."; \
	else \
		echo "🖥️  macOS updates available:"; \
		softwareupdate --list --all 2>&1 | grep -v "Software Update Tool" | grep -v "Finding available software"; \
		if [ "$$YES" = "1" ]; then \
			echo "🖥️  Installing macOS updates (unattended — YES=0 to be asked)..."; \
			sudo softwareupdate --install --all --restart --agree-to-license; \
		else \
			read -p "Install macOS updates? (y/n) " -n 1 -r; \
			echo ""; \
			if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
				sudo softwareupdate --install --all --restart --agree-to-license; \
			else \
				echo "⏭️  Skipping macOS updates."; \
			fi; \
		fi; \
	fi

brew-writable:
	@if [ ! -w "$(BREW_PREFIX)" ]; then \
		echo "❌ Homebrew at $(BREW_PREFIX) is owned by $$(stat -f '%Su' "$(BREW_PREFIX)") and not writable by $(USER_NAME)."; \
		echo "   Run 'make brew-share' once (needs sudo) to share it between both users."; \
		exit 1; \
	fi

brew-share:
	@echo "🔧 Sharing Homebrew at $(BREW_PREFIX) with the 'admin' group..."
	@echo "   Owner: $$(stat -f '%Su' "$(BREW_PREFIX)") — sudo required."
	@sudo chgrp -R admin "$(BREW_PREFIX)"
	@sudo chmod -R g+rwX "$(BREW_PREFIX)"
	@sudo find "$(BREW_PREFIX)" -type d -exec chmod g+s {} +
	@echo "✅ Done! Any user in the admin group can now run brew."
	@echo "   If permissions drift after a Homebrew update, re-run: make brew-share"

brew: brew-writable
	@echo "🍺 Updating Homebrew..."
	@brew update --quiet 2>/dev/null || brew update
	@OUTDATED=$$(brew outdated --greedy-latest 2>/dev/null); \
	if [ -n "$$OUTDATED" ]; then \
		echo "🍺 Upgrading brew-managed packages with --no-quarantine (no Gatekeeper popups)..."; \
		echo "   ℹ️  Self-updating apps (Chrome, VS Code, Slack…) are skipped and update themselves."; \
		HOMEBREW_CASK_OPTS="--no-quarantine" brew upgrade --greedy-latest; \
	else \
		echo "🍺 All Homebrew packages are up to date!"; \
	fi
	@brew autoremove --quiet 2>/dev/null || true

mas:
	@if command -v mas > /dev/null; then \
		OUTDATED=$$(mas outdated 2>/dev/null); \
		if [ -n "$$OUTDATED" ]; then \
			echo "📦 Updating App Store apps..."; \
			mas upgrade; \
		else \
			echo "📦 App Store apps are up to date — skipping."; \
		fi; \
	else \
		echo "⚠️  mas-cli not installed. Run: brew install mas"; \
	fi

microsoft:
	@MSUPDATE_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"; \
	if [ -f "$$MSUPDATE_PATH" ]; then \
		echo "🪟 Checking Microsoft app updates..."; \
		"$$MSUPDATE_PATH" --install; \
	else \
		echo "🪟 Microsoft AutoUpdate not found — skipping."; \
	fi

brew-list:
	@LEAVES=$$(brew leaves 2>/dev/null); CASKS=$$(brew list --casks 2>/dev/null); \
		echo "🍺 Installed Homebrew Formulae (explicitly installed):"; \
		if [ -n "$$LEAVES" ]; then \
			echo "$$LEAVES" | sed 's/^/  /'; \
		else \
			echo "  None"; \
		fi; \
		echo ""; \
		echo "🖥️  Installed Casks (GUI applications):"; \
		if [ -n "$$CASKS" ]; then \
			echo "$$CASKS" | sed 's/^/  /'; \
		else \
			echo "  None"; \
		fi; \
		echo ""; \
		echo "📊 Total: $$(echo "$$LEAVES" | grep -c .) explicitly installed formulae, $$(echo "$$CASKS" | grep -c .) casks"

clean:
	@echo "🧹 Cleaning up..."
	@if [ -w "$(BREW_PREFIX)" ]; then \
		brew cleanup --prune=all 2>/dev/null || true; \
	else \
		echo "  ⏭️  skipped — $(BREW_PREFIX) not writable (run: make brew-share)"; \
	fi
	@echo "📊 Disk space:"
	@df -h / | tail -1 | awk '{print "  Free: " $$4 " of " $$2}'

# Backup & restore for OS reinstallation
#   make dump            → export everything to Brewfile
#   make restore         → reinstall everything on a fresh machine
#   Override path: make dump BREWFILE=~/sync/Brewfile-macbook

BREWFILE ?= Brewfile

dump:
	@echo "💾 Exporting all installed software to $(BREWFILE)..."
	@brew bundle dump --file="$(BREWFILE)" --force
	@echo ""
	@echo "📊 Brewfile summary:"
	@echo "  🍺 Taps:      $$(grep -c '^tap ' "$(BREWFILE)" 2>/dev/null || echo 0)"
	@echo "  🍺 Formulae:  $$(grep -c '^brew ' "$(BREWFILE)" 2>/dev/null || echo 0)"
	@echo "  🖥️  Casks:     $$(grep -c '^cask ' "$(BREWFILE)" 2>/dev/null || echo 0)"
	@echo "  📦 MAS apps:  $$(grep -c '^mas ' "$(BREWFILE)" 2>/dev/null || echo 0)"
	@echo ""
	@echo "✅ Done! Copy $(BREWFILE) to your new machine and run: make restore"

restore: brew-writable
	@echo "🔄 Restoring packages from $(BREWFILE)..."
	@if [ ! -f "$(BREWFILE)" ]; then \
		echo "❌ No $(BREWFILE) found."; \
		echo "   Copy your Brewfile from your old machine first."; \
		echo "   Or run 'make dump' there to create one."; \
		exit 1; \
	fi
	@echo "📋 Packages to install:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@grep -v '^#' "$(BREWFILE)" | grep -v '^$$' | sed 's/^/  /'
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@if [ "$$YES" = "1" ]; then \
		echo "🍺 Installing everything from $(BREWFILE) (unattended — YES=0 to be asked)..."; \
		HOMEBREW_CASK_OPTS="--no-quarantine" brew bundle install --file="$(BREWFILE)" --no-lock; \
		echo "✅ All packages restored!"; \
	else \
		read -p "Install all of the above? This may take a while. (y/n) " -n 1 -r; \
		echo ""; \
		if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
			echo "🍺 Installing everything from $(BREWFILE)..."; \
			HOMEBREW_CASK_OPTS="--no-quarantine" brew bundle install --file="$(BREWFILE)" --no-lock; \
			echo "✅ All packages restored!"; \
		else \
			echo "⏭️  Skipping restore."; \
		fi; \
	fi

# Individual package upgrade
upgrade-%: brew-writable
	@echo "⬆️  Upgrading $(@:upgrade-%=%) with --no-quarantine..."
	@HOMEBREW_CASK_OPTS="--no-quarantine" brew upgrade --greedy $(@:upgrade-%=%) || echo "⚠️  Upgrade failed for $(@:upgrade-%=%)"

# Full fresh-machine setup: packages + dotfiles + macOS prefs
install:
	@chmod +x install.sh
	@./install.sh

link:
	@chmod +x install.sh
	@./install.sh --link-only

macos:
	@bash macos/defaults.sh

# Copy current dotfiles from $HOME into this repo (then commit + push)
DOTFILES_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

dump-dotfiles:
	@echo "👤 Backing up dotfiles for $(USER_NAME) from $$HOME..."
	@mkdir -p home/.ssh home/.warp home/.config/git config/zed config/vscode macos/plists
	@copy() { if [ -f "$$1" ]; then mkdir -p "$$(dirname "$$2")"; cp "$$1" "$$2"; else echo "  ⏭️  skipped $$1 (not found)"; fi; }; \
	copy "$$HOME/.gitconfig" home/.gitconfig; \
	copy "$$HOME/.gitignore_global" home/.gitignore_global; \
	copy "$$HOME/.hgignore_global" home/.hgignore_global; \
	copy "$$HOME/.zprofile" home/.zprofile; \
	copy "$$HOME/.ssh/config" home/.ssh/config; \
	copy "$$HOME/.warp/settings.toml" home/.warp/settings.toml; \
	copy "$$HOME/.config/git/ignore" home/.config/git/ignore; \
	copy "$$HOME/.config/zed/settings.json" config/zed/settings.json; \
	copy "$$HOME/Library/Application Support/Code/User/settings.json" config/vscode/settings.json
	@defaults export com.apple.dock macos/plists/dock.plist
	@defaults export com.apple.controlcenter macos/plists/controlcenter.plist
	@defaults export com.apple.finder macos/plists/finder.plist
	@echo "✅ Dotfiles copied into repo. Review with: git diff"
	@echo "   Then commit and push: git add -A && git commit -m 'Update dotfiles' && git push"
