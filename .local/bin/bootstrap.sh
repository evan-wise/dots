#!/bin/bash
# Author: Evan Wise
# Purpose: Bootstrap dotfiles repository

set -o errexit
set -o nounset

git clone --bare https://github.com/evan-wise/dots $HOME/.local/state/dots/.git
git --git-dir=$HOME/.local/state/dots --work-tree=$HOME checkout -f

# Ask the user if they want to install system packages
read -p "Do you want to install system packages? [y/N] " install_system_packages

if [[ $install_system_packages =~ ^[Yy]$ ]]; then
  $HOME/.local/bin/install.sh
fi

[[ -f $HOME/.bash_profile ]] && . $HOME/.bash_profile
