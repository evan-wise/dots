#!/usr/bin/env bash
# Author: Evan Wise
# Purpose: Installs system packages

set -o errexit
set -o nounset

# Functions
################################################################################

echoerr() {
    echo "$@" 1>&2
}

# Main Body
################################################################################

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "Usage: $0"
            exit 0
            ;;
        *)
            echoerr "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

if command -v pacman &> /dev/null; then
  # If installing in arch, this is a dev laptop
  # Install base-devel, git and rust to bootstrap paru
  if ! command -v paru &> /dev/null; then
    echo "Bootstrapping paru..."
    sudo pacman -Sy --noconfirm base-devel git rustup
    rustup default stable
    mkdir -p src
    pushd src
    git clone https://aur.archlinux.org/paru.git
    pushd paru
    makepkg -si
    popd
    popd
  fi
  # Includes UI packages as well since this is a laptop...
  echo "Installing packages..."
  paru -Sy --noconfirm base-devel git tmux neovim tree-sitter-cli fnm gcc rustup pyright ripgrep ttf-fira-code ttf-nerd-fonts-symbols noto-fonts-emoji lua-language-server greetd hyprland-git hyprpolkitagent-git xdg-desktop-portal-hyprland-git hyprpaper-git hyprlock-git hypridle-git wezterm-git flameshot qt5-wayland qt6-wayland brightnessctl waybar wofi dunst vivaldi gnome-keyring libsecret dropbox libappindicator obsidian keepassxc
  echo "Installing Node.js LTS..."
  fnm install --lts
  echo "Setting up hyprpolkitagent..."
  systemctl --user enable hyprpolkitagent
  echo "Setting up greetd..."
  sudo cp /etc/greetd/config.toml /etc/greetd/config.toml 
  sudo chown root:root /etc/greetd/config.toml
  sudo chmod 644 /etc/greetd/config.toml
  sudo systemctl enable greetd.service
  echo "Setting up NetworkManager..."
  sudo systemctl enable NetworkManager.service
elif command -v apt &> /dev/null; then
  # If installing in Debian or Ubuntu this is a server or WSL VM
  echo "Installing packages..."
  sudo apt install -y build-essential git tmux neovim nodejs npm gcc rustup pyright ripgrep
  if ! command -v brew &> /dev/null; then
    echoerr "Please install brew manually."
    exit 1
  fi
  echo "Installing brew packages..."
  brew install lua-language-server
else
  echoerr "Unsupported package manager."
  exit 1
fi

if ! command -v npm &> /dev/null; then
  echoerr "Please install npm."
  exit 1
fi
echo "Installing npm packages..."
npm install -g typescript-language-server typescript prettier @astrojs/language-server

if [ ! -d "$HOME"/.tmux/plugins/tpm ]; then
  echo "Cloning tpm..."
  git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm
fi
