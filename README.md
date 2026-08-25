# dotfiles

macOS setup: Brewfile, dotfiles, and system preferences to back up and restore everything on this machine.

## Restore on a fresh Mac

```sh
git clone <this-repo-url> ~/dotfiles
cd ~/dotfiles
make install   # or ./install.sh
```

`install.sh` does everything:

1. Installs Homebrew (if missing)
2. Installs all packages from `Brewfile` (formulae, casks, App Store apps, VSCode extensions)
3. Symlinks dotfiles from `home/` and `config/` into place
4. Applies saved macOS preferences from `macos/defaults.sh`

## After the installer — manual steps

- **SSH keys**: copy `~/.ssh/id_ed25519` + `id_ed25519.pub` from the old machine (never committed to git)
- **App Store**: sign in to your Apple ID (needed for `mas` apps: Xcode, Spark, DaVinci Resolve)
- **Settings-synced apps**: sign in to Raycast, Warp, Cursor, Zed — they restore their own settings
- **Browser**: sign in to Chrome/Brave/Zen for bookmarks and profiles

## Update / back up

```sh
cd ~/dotfiles
make update          # update all software
make dump            # regenerate Brewfile
make dump-dotfiles   # copy current dotfiles + macOS prefs into the repo
git add -A && git commit -m "Update backups" && git push
```

## What's backed up

| What | Where |
|---|---|
| Homebrew packages, casks, MAS apps, VSCode extensions | `Brewfile` |
| git, zsh, ssh client configs | `home/` |
| Warp terminal settings | `home/.warp/settings.toml` |
| Zed, VSCode editor settings | `config/` |
| macOS prefs (Dock, Finder, menu bar, dark mode, trackpad) | `macos/` |

## What's NOT backed up (by design)

- SSH private keys, known_hosts
- Raycast access token (recreated on sign-in)
- AI tool local state (~/.claude.json, ~/.codex, ~/.cursor)
- Xcode/Android Studio preferences (large, device-specific)
