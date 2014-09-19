# ~/.profile: executed by the command interpreter for login shells.
# vim:ft=sh:ts=4:sw=4:noet:

# if this is an interactive bash, load .bashrc
if [[ -n "$BASH" && "$-" == *i* ]]; then
	source $HOME/.bashrc
fi

# add private bin to the PATH if it exists
if [ -d "$HOME/.bin" ] ; then
	PATH="$HOME/.bin:$PATH"
fi

# add RVM to the PATH if it's installed
if [ -d "$HOME/.rvm/bin" ]; then
	PATH="$PATH:$HOME/.rvm/bin"
fi

export EDITOR=$(which vim 2>&-)

export DEBFULLNAME="Sam Hanes"
export DEBEMAIL="sam@maltera.com"
