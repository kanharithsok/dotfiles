# dotfiles

macOS setup: Brewfile + Makefile to back up and restore everything installed on this machine.

## Restore on a fresh Mac

1. Install Xcode Command Line Tools:
   ```sh
   xcode-select --install
   ```
2. Install Homebrew:
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
3. Clone this repo and restore everything:
   ```sh
   git clone <this-repo-url> ~/dotfiles
   cd ~/dotfiles
   make restore
   ```
4. Sign in to the App Store (mas apps require it).

## Update / back up

```sh
cd ~/dotfiles
make update    # update everything
make dump      # regenerate Brewfile from current machine
git add Brewfile && git commit -m "Update Brewfile" && git push
```
