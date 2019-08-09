# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# source the profile if we haven't already
if [[ -f "$HOME/.profile" && -z "$have_run_profile" ]]; then
    running_bashrc=yes
    source "$HOME/.profile"
    unset running_bashrc
fi

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
                bright)     _escape+=( '01' );;

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
        echo -en "\003[${_escape[*]}m"
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
        color red
        write "\h "
    else
        color green
        write "\u@\h "
    fi

    if [[ -n "$debian_chroot" ]]; then
        color yellow
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

        color yellow
        write "$venv_name "
    fi

    color blue
    write '\$'
    color reset
    write ' '

    PS1="$_prompt"

    # If this is an xterm set the title to user@host:dir
    case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *)
        ;;
    esac
}

PROMPT_COMMAND="_bashrc_prompt"
$PROMPT_COMMAND

# for the linux console, initialize the color palette
# this is the Solarized Dark color scheme
if [[ $TERM == "linux" ]]; then
    echo -en "\e]R"         # reset palette
    echo -en "\e]P0073642"  # set black         base02
    echo -en "\e]P1DC322F"  # set red           red
    echo -en "\e]P2859900"  # set green         green
    echo -en "\e]P3B58900"  # set yellow        yellow
    echo -en "\e]P4268BD2"  # set blue          blue
    echo -en "\e]P5D33682"  # set magenta       magenta
    echo -en "\e]P62AA198"  # set cyan          cyan
    echo -en "\e]P7EEE8D5"  # set white         base2
    echo -en "\e]P8002B36"  # set br black      base03
    echo -en "\e]P9CB4B16"  # set br red        orange
    echo -en "\e]PA586E75"  # set br green      base01
    echo -en "\e]PB657B83"  # set br yellow     base00
    echo -en "\e]PC839496"  # set br blue       base0
    echo -en "\e]PD6C71C4"  # set br magenta    violet
    echo -en "\e]PE93A1A1"  # set br cyan       base1
    echo -en "\e]PFFDF6E3"  # set br white      base3

    echo -en "\e[00m\e[100;94m\e[8]"

    # clear to the new background color so there aren't artifacts
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi


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

alias ls='ls -Alh --color=auto'
alias psf='ps -fN --pid 2 --ppid 2 --forest'

# keep manpages to a reasonable width, even on big terminals
export MANWIDTH=80

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# load NVM interactive mode if it's installed
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    . "$NVM_DIR/nvm.sh"
    . "$NVM_DIR/bash_completion"
fi

# load rbenv interactive mode if it's installed
if command -v rbenv >/dev/null; then
    export RBENV_ROOT=$HOME/.local/opt/rbenv
    eval "$(rbenv init -)"
fi

if [[ -e "$HOME/.local/bin/aur" ]]; then
    aur () {
        if "$HOME/.local/bin/aur" "$@"; then
            cd "$HOME/aur/$1"
        fi
    }
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

  # support for Homebrew
  if [ -d /usr/local/etc/bash_completion.d ]; then
    for file in /usr/local/etc/bash_completion.d/*; do
      . "$file"
    done
  fi
fi

