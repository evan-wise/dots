#!/usr/bin/env bash
# Author: Evan Wise
# Revision Date: 2024-08-10
# Purpose: Installs dotfiles and sets up home directory

# Exit the script if any command throws an error.
set -o errexit
# Throw an error if referencing an unset variable.
set -o nounset
# Variables
################################################################################

# Get reliable references to script location. `BASH_SOURCE` works even if the
# script is invoked by `.` or `source`.
script_path=${BASH_SOURCE[0]}
script_name=$(basename ${BASH_SOURCE[0]})
script_dir=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)

user_name=$(whoami)
if [ "$user_name" = "root" ]; then
  user_name=$SUDO_USER
fi
home_dir=$(getent passwd "$user_name" | cut -d: -f6)

system_packages="git tmux neovim nodejs gcc pyright ripgrep"
npm_packages="typescript-language-server typescript prettier"

# Main Body
################################################################################

do_install=false
while getopts ":i" opt; do
  case $opt in
    i)
      do_install=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

need_brew=false

if [ "$do_install" = "true" ]; then
  if [ $EUID -ne 0 ]; then
    echo "The -i option for this script must be run with administrative privileges." >&2
    exit 1
  fi

  if command -v pacman &> /dev/null; then
    echo ""
    echo "Installing system packages..."
    pacman -S --noconfirm $system_packages wezterm ttf-fira-code ttf-nerd-fonts-symbols noto-fonts-emoji lua-language-server
    echo ""
  elif command -v apt &> /dev/null; then
    need_brew=true
    echo ""
    echo "Installing system packages..."
    echo ""
    if [ ! -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
      echo "Please install brew first..."
      exit 1
    fi
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    apt install -y $system_packages wezterm fonts-firacode npm
    sudo -u $user_name /home/linuxbrew/.linuxbrew/bin/brew install lua-language-server
    echo ""
  else
    echo ""
    echo "Unsupported package manager. Please install the following packages manually:"
    for pkg in $system_packages
    do
      echo " * $pkg"
    done
  fi

  if ! command -v npm &> /dev/null; then
    echo ""
    echo "Please install the following npm packages manually:"
    for pkg in $npm_packages
    do
      echo " * $pkg"
    done
  fi
  echo ""
  echo "Installing npm packages..."
  echo ""
  npm install -g $npm_packages
  echo ""
fi


echo ""
echo "Deploying config files and creating directories..."
rsync -a "$script_dir"/home/ "$home_dir"

if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
  need_brew=true
fi
if [ "$need_brew" = "true" ]; then
  (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> $home_dir/.bashrc
fi

if [ ! -d "$home_dir"/.tmux/plugins/tpm ]; then
  echo ""
  echo "Cloning tpm..."
  git clone https://github.com/tmux-plugins/tpm "$home_dir"/.tmux/plugins/tpm
  # In case we are running from sudo
  chown -R $user_name:$user_name "$home_dir"/.tmux/plugins/tpm
fi

echo "Don't forget to source your .bashrc!"

