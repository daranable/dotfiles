# ~/.bash_logout: executed by bash(1) when login shell exits.

# when leaving the console clear the screen to increase privacy

if [ "$SHLVL" = 1 ]; then
    if [ "$TERM" = "linux" ]; then
        echo -en "\e]R\ec" # reset palette
    fi

    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi
