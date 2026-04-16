# Author: Evan Wise
# Revision Date: 2026-04-08

################################################################################
# Shell settings
################################################################################

bindkey -v # vi mode

# Edit command line with Ctrl+x,e
autoload edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line

################################################################################
# Variables
################################################################################

# Use neovim as the default editor.
if command -v nvim >/dev/null 2>&1; then
  VISUAL=$(which nvim); export VISUAL
  EDITOR=$(which nvim); export EDITOR
else
  VISUAL=$(which vi); export VISUAL
  EDITOR=$(which vi); export EDITOR
fi

# Add homebrew installs to path, if found.
[[ -d /opt/homebrew/bin ]] && PATH="/opt/homebrew/bin:$PATH"

# Add dotnet tools to path, if found.
[[ -d "$HOME/.dotnet/tools" ]] && PATH="$PATH:$HOME/.dotnet/tools"

# Prepend user scripts and local installs.
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Load extra system specific variables (not in source control)
[[ -f "$HOME/.zvariables" ]] && . "$HOME/.zvariables"

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

# The secret sauce, appends aliases to the end of ~/.zaliases
#   Note: Ideally, you should comb through these periodically and add
#   explanation where it seems useful.
# $1 - The alias
# $2 - The command to substitute, in single quotes.
# $3 - (Optional) A comment.
idiom() {
    if [ -z "$1" ]; then
        echoerr "Usage:\n\"idiom foo bar\" adds the line \"alias foo='bar'\" to ~/.zaliases.\n\"idiom foo bar baz\" adds the line \"alias foo='bar' # baz\" to ~/.zaliases." 
        return 1
    else
        _idiom_alias="$1"
    fi
    if [ -z "$2" ]; then
        echoerr "Usage:\n\"idiom foo bar\" adds the line \"alias foo='bar'\" to ~/.zaliases.\n\"idiom foo bar baz\" adds the line \"alias foo='bar' # baz\" to ~/.zaliases." 
        return 1
    else
        _idiom_subst="$2"
    fi
    if [ ! -z "$3" ]; then
        _idiom_comment="$3"
    fi
    if [ ! -z "$4" ]; then
        echoerr "Usage:\n\"idiom foo bar\" adds the line \"alias foo='bar'\" to ~/.zaliases.\n\"idiom foo bar baz\" adds the line \"alias foo='bar' # baz\" to ~/.zaliases."
        return 1
    fi

    if [ ! -f "$HOME/.zaliases" ]; then
        echo '# This file is maintained by the idiom function in ~/.zshrc.' > "$HOME/.zaliases"
    fi

    if [ -z "$_idiom_comment" ]; then
        _idiom_comment=" # ""$(date)"
    else
        _idiom_comment=" # ""$_idiom_comment"" - ""$(date)"
    fi

    echo "alias ""$_idiom_alias""='""$_idiom_subst""'""$_idiom_comment" >> "$HOME/.zaliases" 

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

    if [ ! -f "$HOME/.zmemos" ]; then
        echo '# This file is maintained by the memo function in ~/.zshrc.' > "$HOME/.zmemos"
    fi

    echo "$_memo_command""$_memo_comment" >> "$HOME/.zmemos"

    return 0
}

# Load extra system specific functions (not in source control)
[[ -f "$HOME/.zfunctions" ]] && . "$HOME/.zfunctions"

################################################################################
# Aliases
################################################################################

# Special git alias for managing dotfiles.
########################################
alias .git='/usr/bin/git --git-dir=$HOME/.local/state/dots/.git --work-tree=$HOME'

# Setting helpful default flags
########################################

# Use vim key binding for info.
alias info='info --vi-keys'
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Workaround for password store autodetection not working right with
# gnome-keyring under Hyprland.
if command -v vivaldi >/dev/null 2>&1; then
  alias vivaldi='vivaldi --password-store=gnome-libsecret'
fi

# Keystroke savers
########################################

# Use long listing format with ls and show file size.
alias ll='ls -lAsh'

# Pipe ls output to grep
alias lg='ls -lAsh | grep'

# Jump up a directory.
alias ..='cd ..'

# Source .zshrc
alias .~='. ~/.zshrc'

# Vim habits die hard...
alias vim='nvim'
alias :e='nvim'
alias :q='echo "Exit? (Y/n)";read ANS;case $ANS in Y | y ) exit ;; N | n ) ;; * ) ;; esac'

# Idioms (should be last)
########################################

[[ -f "$HOME/.zaliases" ]] && . "$HOME/.zaliases"

################################################################################
# Tool Setup
################################################################################

# fnm
eval "$(fnm env --use-on-cd --shell zsh)"

# gcloud
export CLOUDSDK_PYTHON=$(which python3)
[[ -f "$HOME/src/google-cloud-sdk/path.zsh.inc" ]] && . "$HOME/src/google-cloud-sdk/path.zsh.inc"
[[ -f "$HOME/src/google-cloud-sdk/completion.zsh.inc" ]] && . "$HOME/src/google-cloud-sdk/completion.zsh.inc"

################################################################################
# Prompt
################################################################################

BRANCH_ICON=$'\xef\x84\xa6'

_prompt_precmd() {
  local git_part=""
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch=$(git rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    git_part=" %F{yellow}${BRANCH_ICON} ${branch}%f"
  fi
  PROMPT="%F{green}%n@%m%f %F{blue}%~%f${git_part} %F{white}❯%f "
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _prompt_precmd
