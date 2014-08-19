# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# detect Max OS X
have_osx=$([[ "$(uname -s)" == "Darwin" ]])

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    function _bashrc_color {
        local -a _escape=( '00' )
        local _base='3' # foreground

        for token in "$@"; do
            case "$token" in
                bold)       _escape+=( '01' );;

                black)      _escape+=( "${_base}0" );;
                red)        _escape+=( "${_base}1" );;
                green)      _escape+=( "${_base}2" );;
                yellow)     _escape+=( "${_base}3" );;
                blue)       _escape+=( "${_base}4" );;
                magenta)    _escape+=( "${_base}5" );;
                cyan)       _escape+=( "${_base}6" );;
                white)      _escape+=( "${_base}7" );;

                fore|foreground) _base='3';;
                back|background) _base='4';;

                reset)
                    _escape=( '00' )
                    break ;;
            esac
        done

        local IFS=";${IFS}"
        echo -en "\033[${_escape[*]}m"
    }
else
    function _bashrc_color { echo -n ""; }
fi

function _bashrc_prompt {
    local _prompt=''

    function color {
        local _color="$(_bashrc_color "$@")"
        if [[ -n "$_color" ]]; then
            _prompt="${_prompt}\[\e${_color:1}\]"
        fi
    }

    function write {
        _prompt="${_prompt}$*"
    }

    if [[ 0 -eq $UID ]]; then
        color bold red
        write "\h "
    else
        color bold green
        write "\u@\h "
    fi

    if [[ -n "$debian_chroot" ]]; then
        color bold yellow
        write "($debian_chroot) "
    fi

    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_name="$(basename "$VIRTUAL_ENV")"
        if [[ "." == "${venv_name:0:1}" ]]; then
            local venv_dir="$(basename "$(dirname "$VIRTUAL_ENV")")"
            if [[ "." != "${venv_dir:0:1}" ]]; then
                venv_name="$venv_dir"
            fi
        fi

        color bold yellow
        write "$venv_name "
    fi

    color bold blue
    write '\$'
    color reset
    write ' '

    PS1="$_prompt"
}

PROMPT_COMMAND="_bashrc_prompt"
$PROMPT_COMMAND

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# we handle virtualenv prompts ourselves
export VIRTUAL_ENV_DISABLE_PROMPT=yes

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

if $have_osx; then
    alias ls='ls -AlhG'
    alias psf='ps -Af'
else
    alias ls='ls -Alh --color=auto'
    alias psf='ps -fN --pid 2 --ppid 2 --forest'
fi

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Add an alias to feh to start Fullscreen and auto-zoom.
alias feh='feh -ZF'

# load rbenv if it's installed
if which rbenv >&/dev/null; then
    eval "$(rbenv init -)"
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
