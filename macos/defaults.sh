#!/usr/bin/env bash
# Apply saved macOS system preferences. Safe to re-run.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🖥️  Applying macOS preferences..."

# Dock (full restore of layout/position)
defaults import com.apple.dock "$DIR/plists/dock.plist" 2>/dev/null || true

# Control Center / menu bar items
defaults import com.apple.controlcenter "$DIR/plists/controlcenter.plist" 2>/dev/null || true

# Finder
defaults import com.apple.finder "$DIR/plists/finder.plist" 2>/dev/null || true

# Appearance: Dark mode
defaults write -g AppleInterfaceStyle -string "Dark"

# Trackpad: right-click bottom-right corner, no tap-to-click, no 3-finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false

# Restart affected apps
killall Dock Finder SystemUIServer 2>/dev/null || true

echo "✅ macOS preferences applied."
