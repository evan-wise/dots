#!/bin/bash
# Author: Evan Wise
# Purpose: Bootstrap dotfiles repository

set -o errexit
set -o nounset

git clone --bare https://github.com/evan-wise/dots $HOME/.local/state/dots/.git
git --git-dir=$HOME/.local/state/dots/.git --work-tree=$HOME checkout -f

gitconfig="$HOME/.gitconfig"
include_block=$'[include]\n\tpath = ~/.gitconfig-common'
if [ ! -f "$gitconfig" ]; then
  echo "Creating .gitconfig with common include..."
  printf '%s\n' "$include_block" > "$gitconfig"
elif ! grep -q 'path = ~/.gitconfig-common' "$gitconfig"; then
  echo "Prepending common include to .gitconfig..."
  tmpfile=$(mktemp)
  printf '%s\n' "$include_block" > "$tmpfile"
  cat "$gitconfig" >> "$tmpfile"
  mv "$tmpfile" "$gitconfig"
fi

# Ask the user if they want to install system packages
read -p "Do you want to install system packages? [y/N] " install_system_packages

if [[ $install_system_packages =~ ^[Yy]$ ]]; then
  $HOME/.local/bin/install.sh
fi

if [[ "$SHELL" == */zsh ]]; then
  [[ -f $HOME/.zshrc ]] && . $HOME/.zshrc
else
  [[ -f $HOME/.bashrc ]] && . $HOME/.bashrc
fi

