# ~/.profile: executed by the command interpreter for login shells.
# vim:ft=sh:ts=4:sw=4:noet:

# this is used by .bashrc
export have_run_profile=yes

# on OS X, load Homebrew GNU bin dirs
if [[ -d /usr/local/Cellar ]]; then
	for dir in $(find /usr/local/Cellar \( -type d -a -name gnubin \)); do
		PATH="$dir:$PATH"
	done
fi

# if this is an interactive bash, load .bashrc
# unless we're being called from .bashrc
if [[ -n "$BASH" && "$-" == *i* && -z "$running_bashrc" ]]; then
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


# if the modern (2.1+) GPG agent is installed, start it
# and interrogate it to set the legacy environment variables
if command -v gpg-connect-agent >/dev/null 2>&1; then
	export $(gpg-connect-agent <<-'END'
		/subst
		/serverpid
		/echo GPG_AGENT_INFO=${get homedir}/S.gpg-agent:${get serverpid}:1
		/echo SSH_AUTH_SOCK=${get homedir}/S.gpg-agent.ssh
		/echo SSH_AGENT_PID=${get serverpid}
		/bye
		END
	)

# if we have an environment file from an older GPG agent, use that
elif [[ -f "$HOME/.gnupg/gpg-agent-info" ]]; then
	source "$HOME/.gnupg/gpg-agent-info"
fi

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
