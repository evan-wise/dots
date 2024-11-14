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
aur_packages=""
npm_packages="typescript-language-server typescript prettier @astrojs/language-server"

if command -v pacman &> /dev/null; then
  install_cmd="pacman -S --noconfirm"
  system_packages="base-devel git tmux neovim nodejs gcc pyright ripgrep ttf-fira-code ttf-nerd-fonts-symbols noto-fonts-emoji lua-language-server"
  aur_packages=""
  if [ "$install_gui" = "true" ]; then
    aur_packages=$aur_packages" hyprpolkitagent-git xdg-desktop-portal-hyprland-git hyprpaper-git"
    system_packages=$system_packages" hyprland qt5-wayland qt6-wayland hyprlock waybar wofi dunst wezterm"
  fi
elif command -v apt &> /dev/null; then
  if [ "$install_gui" = "true" ]; then
    echoerr "GUI installation is not supported on apt based systems."
    exit 1
  fi
  install_cmd="apt install -y"
  system_packages="build-essential git tmux neovim nodejs npm gcc pyright ripgrep"
  brew_packages="lua-language-server"
else
  echo "Unsupported package manager."
  exit 1
fi

echo "Installing system packages..."
$install_cmd $system_packages

if [ "$install_gui" = "true" ]; then
  echo "Installing gui packages..."
  $install_cmd $gui_packages
fi


if [ ! -z "$aur_packages" ]; then
  if ! command -v paru &> /dev/null; then
    echoerr "Please install paru manually."
    exit 1
  fi
  echo "Installing AUR packages..."
  sudo -u $user_name paru -S --noconfirm $aur_packages
fi

if [ ! -z "$brew_packages" ]; then
  if ! command -v brew &> /dev/null; then
    echoerr "Please install brew manually."
    exit 1
  fi
  echo "Installing brew packages..."
  sudo -u $user_name brew install $brew_packages
fi

if ! command -v npm &> /dev/null; then
  echoerr "Please install npm."
  exit 1
fi
echo "Installing npm packages..."
npm install -g $npm_packages

if [ ! -d "$home_dir"/.tmux/plugins/tpm ]; then
  echo "Cloning tpm..."
  git clone https://github.com/tmux-plugins/tpm "$home_dir"/.tmux/plugins/tpm
  # In case we are running from sudo
  chown -R $user_name:$user_name "$home_dir"/.tmux/plugins/tpm
fi

