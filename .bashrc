# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000
HISTIGNORE='ls:bg:fg:history'
HISTTIMEFORMAT='%F %T '

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Reset
Color_Off='\e[0m'

# Regular Colors
Black='\e[0;30m'
Red='\e[0;31m'
Green='\e[0;32m'
Yellow='\e[0;33m'
Blue='\e[1;34m'
Purple='\e[0;35m'
Cyan='\e[0;36m'
White='\e[0;37m'

function __prompt_command() {
    EXIT="$?"
    PS1=""

    # command history number in green if ok, red - if not
    if [ $EXIT -eq 0 ]; then PS1+="\[$Blue\][\!]\[$Color_Off\] "; else PS1+="\[$Red\][\!]\[$Color_Off\] "; fi

    # basic information (user@host:path)
    PS1+="\[$Blue\]\u\[$Color_Off\]@\[$Blue\]\h\[$Color_Off\]:\w "

    # prompt $ or # for root
    PS1+='\n\$ '
}

PROMPT_COMMAND=__prompt_command

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    # -N gets rid of nasty apostrophe in file listing
    alias ls='ls --color=auto -N'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# less customization
export LESS='-M -I -# 4'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias myip='ip -br -c a'

# go settings
export GOPATH=/data

# bash variables
export EDITOR=vim
export PATH=$HOME/bin:$PATH
