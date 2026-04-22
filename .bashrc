# Author: Evan Wise
# Revision Date: 2026-04-08

################################################################################
# Shell settings
################################################################################
set -o vi

################################################################################
# Variables
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

# Set homebrew environment variables (if applicable).
if [ -d /home/linuxbrew/.linuxbrew ]; then
  eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi

# Load extra system specific variables (not in source control)
[[ -f "$HOME/.bash_variables" ]] && . "$HOME/.bash_variables"

################################################################################
# Functions
################################################################################

# Echo to stderr
echoerr() {
    echo "$@" 1>&2
}

# cd then ls
cdl() {
    cd "$@" && ls
}

# The secret sauce, appends aliases to the end of ~/.bash_aliases
#   Note: Ideally, you should comb through these periodically and add
#   explanation where it seems useful.
# $1 - The alias
# $2 - The command to substitute, in single quotes.
# $3 - (Optional) A comment.
idiom() {
    if [ -z "$1" ]; then
        echoerr "Usage:\n\"idiom foo bar\" adds the line \"alias foo='bar'\" to ~/.bash_aliases.\n\"idiom foo bar baz\" adds the line \"alias foo='bar' # baz\" to ~/.bash_aliases." 
        return 1
    else
        _idiom_alias="$1"
    fi
    if [ -z "$2" ]; then
        echoerr "Usage:\n\"idiom foo bar\" adds the line \"alias foo='bar'\" to ~/.bash_aliases.\n\"idiom foo bar baz\" adds the line \"alias foo='bar' # baz\" to ~/.bash_aliases." 
        return 1
    else
        _idiom_subst="$2"
    fi
    if [ ! -z "$3" ]; then
        _idiom_comment="$3"
    fi
    if [ ! -z "$4" ]; then
        echoerr "Usage:\n\"idiom foo bar\" adds the line \"alias foo='bar'\" to ~/.bash_aliases.\n\"idiom foo bar baz\" adds the line \"alias foo='bar' # baz\" to ~/.bash_aliases."
        return 1
    fi

    if [ ! -f "$HOME/.bash_aliases" ]; then
        echo '# This file is maintained by the idiom function in ~/.bashrc.' > "$HOME/.bash_aliases"
    fi

    if [ -z "$_idiom_comment" ]; then
        _idiom_comment=" # ""$(date)"
    else
        _idiom_comment=" # ""$_idiom_comment"" - ""$(date)"
    fi

    echo "alias ""$_idiom_alias""='""$_idiom_subst""'""$_idiom_comment" >> "$HOME/.bash_aliases" 

    return 0
}

# Used to log commands you want to recall later
# $1 - The command to log, in single quotes.
# $2 - (Optional) A comment.
memo() {
    if [ -z "$1" ]; then
        echoerr "error 1: memo: Expected a command as the first argument."
        return 1
    else
        _memo_command="$1"
    fi

    if [ -z "$2" ]; then
        _memo_comment=" # ""$(date)"
    else
        _memo_comment=" # ""$2"" - ""$(date)"
    fi

    if [ ! -z "$3" ]; then
        echoerr "error: memo: Unexpected Argument $3"
        return 1
    fi

    if [ ! -f "$HOME/.bash_memos" ]; then
        echo '# This file is maintained by the memo function in ~/.bashrc.' > "$HOME/.bash_memos"
    fi

    echo "$_memo_command""$_memo_comment" >> "$HOME/.bash_memos"

    return 0
}

# Load extra system specific functions (not in source control)
[[ -f "$HOME/.bash_functions" ]] && . "$HOME/.bash_functions"

################################################################################
# Aliases
################################################################################

# Special git alias for managing dotfiles.
########################################
alias .git='/usr/bin/git --git-dir=$HOME/.local/state/dots/.git --work-tree=$HOME'

# Setting helpful flags
########################################

# Use vim key binding for info.
alias info='info --vi-keys'
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Workaround for password store autodetection not working right with
# gnome-keyring under Hyprland.
alias vivaldi='vivaldi --password-store=gnome-libsecret'

# Keystroke savers
########################################

# Use long listing format with ls and show file size.
alias ll='ls -lAsh'

# Pipe ls output to grep
alias lg='ls -lAsh | grep'

# Jump up a directory.
alias ..='cd ..'

# Source .bashrc
alias .~='. ~/.bashrc'

# Vim habits die hard...
alias vim='nvim'
alias :e='nvim'
alias :q='echo "Exit? (Y/n)";read ANS;case $ANS in Y | y ) exit ;; N | n ) ;; * ) ;; esac'

# Idioms (should be last)
########################################

[[ -f "$HOME/.bash_aliases" ]] && . "$HOME/.bash_aliases"

################################################################################
# Tool Setup
################################################################################

# fnm
eval "$(fnm env --use-on-cd --shell bash)"

################################################################################
# Prompt
################################################################################

BRANCH_ICON=$'\xef\x84\xa6'

_prompt_command() {
  local git_part="" prompt_char branch_prefix
  if [[ "$TERM" == "linux" ]]; then
    prompt_char=">"
    branch_prefix=""
  else
    prompt_char="❯"
    branch_prefix="${BRANCH_ICON} "
  fi
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch=$(git rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    git_part=" \033[33m${branch_prefix}${branch}\033[0m"
  fi
  PS1="\033[32m\u@\h\033[0m \033[34m\w\033[0m${git_part} \033[37m${prompt_char}\033[0m "
}

PROMPT_COMMAND=(_prompt_command)

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

