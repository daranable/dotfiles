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
    move_link ".files/$1" "$2"
}


normal bash_logout
normal bashrc
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

mkdir -p .xmonad
special xmonad.hs .xmonad/xmonad.hs
