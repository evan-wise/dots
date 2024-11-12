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

# Variables
################################################################################

user_name=$(whoami)
if [ "$user_name" = "root" ]; then
  user_name=$SUDO_USER
fi
home_dir=$(getent passwd "$user_name" | cut -d: -f6)
arch_packages="git tmux neovim nodejs gcc pyright ripgrep ttf-fira-code ttf-nerd-fonts-symbols noto-fonts-emoji lua-language-server"
ubuntu_packages="git tmux neovim nodejs npm gcc pyright ripgrep fonts-fira-code"
ubuntu_brew_packages="lua-language-server"
npm_packages="typescript-language-server typescript prettier @astrojs/language-server"
gui_packages="hyprland hyprpaper hyprlock waybar wofi wezterm"

# Main Body
################################################################################

# Handle --gui option which installs hyprland and other gui programs.
install_gui=false
while [ $# -gt 0 ]; do
    case "$1" in
        -g|--gui)
            install_gui=true
            ;;
        -h|--help)
            echo "Usage: $0 [--gui] [-g]"
            exit 0
            ;;
        *)
            echoerr "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done


if [ $EUID -ne 0 ]; then
  echoerr "This script must be run with administrative privileges." >&2
  exit 1
fi

install_cmd=""
system_packages=""
brew_packages=""

if command -v pacman &> /dev/null; then
  install_cmd="pacman -S --noconfirm"
  system_packages=$arch_packages
elif command -v apt &> /dev/null; then
  install_cmd="apt install -y"
  system_packages=$ubuntu_packages
  brew_packages=$ubuntu_brew_packages
else
  echo "Unsupported package manager. Please install the following packages manually:"
  for pkg in $arch_packages
  do
    echo " * $pkg"
  done
fi

echo "Installing system packages..."
$install_cmd $system_packages

if [ "$install_gui" = "true" ]; then
  echo "Installing gui packages..."
  $install_cmd $gui_packages
fi

if [ ! -z "$brew_packages" ]; then
  if [ ! -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    echo "Please install Homebrew manually."
    exit 1
  fi
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  sudo -u $user_name /home/linuxbrew/.linuxbrew/bin/brew install $brew_packages
fi

if ! command -v npm &> /dev/null; then
  echo "Please install the following npm packages manually:"
  for pkg in $npm_packages
  do
    echo " * $pkg"
  done
fi
echo "Installing npm packages..."
npm install -g $npm_packages

if [ ! -d "$home_dir"/.tmux/plugins/tpm ]; then
  echo "Cloning tpm..."
  git clone https://github.com/tmux-plugins/tpm "$home_dir"/.tmux/plugins/tpm
  # In case we are running from sudo
  chown -R $user_name:$user_name "$home_dir"/.tmux/plugins/tpm
fi

