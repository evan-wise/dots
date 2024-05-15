# Author: Evan Wise
# Revision Date: 2024-05-14

################################################################################
# Environment variable manipulation.
################################################################################

# Use neovim as the default editor.
if [ -e /usr/bin/nvim ] ; then
    VISUAL=/usr/bin/nvim; export VISUAL
    EDITOR=/usr/bin/nvim; export EDITOR
else
    VISUAL=/usr/bin/vi; export VISUAL
    EDITOR=/usr/bin/vi; export EDITOR
fi

# Add local bin folders to the PATH.
export PATH=$PATH:$HOME/bin:$HOME/.local/bin

################################################################################
# Prompt
################################################################################
PS1='[\u@\h \W]\$ '

case ${TERM} in
  Eterm*|alacritty*|aterm*|foot*|gnome*|konsole*|kterm*|putty*|rxvt*|tmux*|xterm*)
    PROMPT_COMMAND+=('printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"')

    ;;
  screen*)
    PROMPT_COMMAND+=('printf "\033_%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"')
    ;;
esac

if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  . /usr/share/bash-completion/bash_completion
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
