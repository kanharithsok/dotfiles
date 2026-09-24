#!/usr/bin/env bash
# Bootstrap a fresh macOS machine from this repo.
# Usage: ./install.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

if [ "${1:-}" = "--link-only" ]; then
  LINK_ONLY=1
else
  LINK_ONLY=0
fi

# 1. Homebrew
if [ "$LINK_ONLY" -eq 0 ] && ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [ -f /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
if [ -f /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi

# 2. All packages from Brewfile
if [ "$LINK_ONLY" -eq 0 ]; then
  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew not found in PATH — install it first: https://brew.sh"
    exit 1
  fi
  BREW_PREFIX="$(brew --prefix)"
  if [ ! -w "$BREW_PREFIX" ]; then
    log "Homebrew at $BREW_PREFIX is owned by $(stat -f '%Su' "$BREW_PREFIX") and not writable by $(whoami)."
    log "If another user already installed Homebrew, ask them to run 'make brew-share' once, then re-run this script."
    exit 1
  fi
  log "Installing packages from Brewfile..."
  HOMEBREW_CASK_OPTS="--no-quarantine" brew bundle install --file="$DOTFILES/Brewfile" --no-lock
fi

# 3. Symlink home dotfiles (backups are made if real files exist)
link() {
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then
    log "Skipping $dst (missing $src)"
    return
  fi
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak-$(date +%Y%m%d%H%M%S)"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  log "Linked $dst"
}

link "$DOTFILES/home/.gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES/home/.gitignore_global" "$HOME/.gitignore_global"
link "$DOTFILES/home/.hgignore_global"  "$HOME/.hgignore_global"
link "$DOTFILES/home/.zprofile"         "$HOME/.zprofile"
link "$DOTFILES/home/.ssh/config"       "$HOME/.ssh/config"
link "$DOTFILES/home/.warp/settings.toml" "$HOME/.warp/settings.toml"
link "$DOTFILES/home/.config/git/ignore"  "$HOME/.config/git/ignore"
link "$DOTFILES/config/zed/settings.json" "$HOME/.config/zed/settings.json"
link "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

# 4. macOS system preferences
if [ "$LINK_ONLY" -eq 0 ]; then
  log "Applying macOS preferences..."
  bash "$DOTFILES/macos/defaults.sh"
fi

log "Done! Next manual steps:"
log "  - Copy ~/.ssh/id_ed25519* from your old machine (or create new keys)"
log "  - Sign in to the App Store, then run: mas list"
log "  - Sign in to Raycast, Warp, Cursor, Zed for settings sync"
