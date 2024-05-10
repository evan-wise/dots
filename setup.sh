#!/usr/bin/env bash
# Author: Evan Wise
# Revision Date: 2024-05-10
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

user_name=$(logname)
home_dir=/home/$user_name

system_packages="git wezterm ttf-fira-code ttf-nerd-fonts-symbols noto-fonts-emoji tmux neovim nodejs lua-language-server"
npm_packages="typescript-language-server typescript"

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

if [ "$do_install" = "true" ]; then
  if [ $EUID -ne 0 ]; then
    echo "The -i option for this script must be run with administrative privileges." >&2
    exit 1
  fi

  if command -v pacman &> /dev/null; then
    echo ""
    echo "Installing system packages..."
    pacman -S --noconfirm $system_packages
  elif command -v apt &> /dev/null; then
    echo ""
    echo "Installing system packages..."
    apt install -y $system_packages
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
  npm install -g $npm_packages
fi


echo "Deploying config files and creating directories..."
rsync -a "$script_dir"/home/ "$home_dir"

if [ ! -d "$home_dir"/.tmux/plugins/tpm ]; then
  echo ""
  echo "Cloning tpm..."
  git clone https://github.com/tmux-plugins/tpm "$home_dir"/.tmux/plugins/tpm
  # In case we are running from sudo
  chown -R $user_name:$user_name "$home_dir"/.tmux/plugins/tpm
fi

