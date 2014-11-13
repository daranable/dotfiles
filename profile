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


#######################################################################
# Java Runtime Options                                                #
#######################################################################
declare -a opts

# use proper anti-aliased fonts
opts+=(
	'-Dawt.useSystemAAFontSettings=on'
	'-Dswing.aatext=true'
)

# use the GTK look and feel for Swing
opts+=(
	'-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel'
	'-Dswing.crossplatformlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel'
)

export JAVA_TOOL_OPTIONS="${opts[*]}"
unset opts
