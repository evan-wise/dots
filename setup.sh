#!/usr/bin/env bash
# Author: Evan Wise
# Revision Date: 2024-05-05
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

# Main Body
################################################################################

echo "Deploying config files and creating directories..."
rsync -a "$script_dir"/home/ ~ 

if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo "Cloning tpm..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo ""
echo "Don't forget to install the following system packages:"
system_packages="wezterm ttf-fira-code ttf-nerd-fonts-symbols noto-fonts-emoji tmux neovim nodejs lua-language-server"
for pkg in $system_packages
do
  echo " * $pkg"
done
echo ""
echo "Don't forget to install the following npm packages:"
npm_packages="typescript-language-server typescript"
for pkg in $npm_packages
do
  echo " * $pkg"
done
echo ""

