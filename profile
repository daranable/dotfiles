# ~/.profile: executed by the command interpreter for login shells.
# vim:ft=sh:ts=4:sw=4:noet:
#
# I explicitly don't source the bashrc as I configure my environments
# to get the difference between login and interactive shells correct.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

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
