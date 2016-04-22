#!/bin/bash

cd $HOME

move_link () {
    if [[ -e "$2" ]]; then
        mv "$2" "$2.old"
    fi

    ln -s "$1" "$2"
}

normal () {
    move_link ".files/$1" ".$1"
}

special () {
    move_link "$1" "$2"
}


normal bash_logout
normal bashrc
normal dircolors
normal hgignore
normal hgrc
normal gitconfig
normal gitignore
normal profile
normal vim
normal Xresources
normal xmobarrc
normal stalonetrayrc

move_link .vim/vimrc .vimrc

mkdir -p .gnupg
special ../.files/gpg.conf .gnupg/gpg.conf
special ../.files/gpg-agent.conf .gnupg/gpg-agent.conf

mkdir -p .xmonad
special ../.files/xmonad.hs .xmonad/xmonad.hs
