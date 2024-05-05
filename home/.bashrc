# Author: Evan Wise
# Revision Date: 2024-05-05

################################################################################
# Bash shell options
################################################################################
# Use vi editor mode.
set -o vi

################################################################################
# Environment variable manipulation.
################################################################################
#
# Use neovim as the default editor.
if [ -e /usr/bin/nvim ] ; then
    VISUAL=/usr/bin/nvim; export VISUAL
    EDITOR=/usr/bin/nvim; export EDITOR
else
    VISUAL=/usr/bin/vi; export VISUAL
    EDITOR=/usr/bin/vi; export EDITOR
fi

################################################################################
# Aliases
################################################################################

# Setting helpful default flags
########################################

# Use vim key binding for info.
alias info='info --vi-keys'
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Keystroke savers
########################################

# Use long listing format with ls and show file size.
alias ll='ls -lAsh'

# Pipe ls output to grep
alias lg='ls -lAsh | grep'

# Quickly edit this file.
alias e~='nvim ~/.bashrc'
# Quickly source this file.
alias .~='. ~/.bashrc'

# Jump up a directory.
alias ..='cd ..'

# Vim habits die hard...
alias :e='nvim'
alias :q='echo "Exit?(Y/n)";read ANS;case $ANS in Y | y ) exit ;; N | n ) ;; * ) ;; esac'

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

    if [ ! -f ~/.bash_aliases ]; then
        echo '# This file is maintained by the idiom function in ~/.bashrc.' > ~/.bash_aliases
    fi

    if [ -z "$_idiom_comment" ]; then
        _idiom_comment=" # ""$(date)"
    else
        _idiom_comment=" # ""$_idiom_comment"" - ""$(date)"
    fi

    echo "alias ""$_idiom_alias""='""$_idiom_subst""'""$_idiom_comment" >> ~/.bash_aliases 

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

    if [ ! -f ~/.bash_memos ]; then
        echo '# This file is maintained by the memo function in ~/.bashrc.' > ~/.bash_memos
    fi

    echo "$_memo_command""$_memo_comment" >> ~/.bash_memos

    return 0
}

################################################################################
# Import idioms (should be last)
################################################################################

# Import .bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
