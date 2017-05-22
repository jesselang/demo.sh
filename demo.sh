#!/usr/bin/env bash

echo -en hello | grep -q '-en' -
ECHO_EN=$?

if [ $ECHO_EN -eq 0 ]; then
    echo "error: demo.sh requires a bash-compatible shell; your script is using:" >&2
    head -1 ${0} >&2
    exit 1
fi

SPEED="0.1"
MUTED="\033[38;5;242m"
NORMAL="\033[0m"
TRAP=

_prompt() {
    echo -en "\r${MUTED}${1-demo}>${NORMAL} "
}

_trap() {
    [ $TRAP ] || trap "echo -en \"\\r\"" EXIT; _prompt; TRAP=set;
}

_write() {
    _trap
    sleep $SPEED
    sleep $SPEED

    output=$@

    for (( i=0; i<${#output}; i++ )); do
        echo -n "${output:$i:1}"
        sleep $SPEED
    done

    echo
}

c() {
    _write "# ${@}"
    _prompt
}

x() {
    _write "$@"
    eval "$@"
    _prompt
}

hold() {
    _prompt hold
    read -rsn 1
    _prompt
}

shell() {
    echo -en "\r"
    PS1="${MUTED}live>${NORMAL} " bash
    echo -en "\033[1A" # move up 1 line
    echo -en "\033[2K" # clear entire line
    _prompt
}

if [ "$0" = "${BASH_SOURCE}" ]; then
    c Welcome to demo.sh
fi


