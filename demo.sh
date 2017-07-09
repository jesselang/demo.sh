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
DEMO_PROMPT=demo
TRAP=

_prompt() {
    echo -en "\r${MUTED}${1-${DEMO_PROMPT}}>${NORMAL} "
}

_trap() {
    [ $TRAP ] || trap "echo -en \"\\r\"" EXIT; _prompt; TRAP=set;
}

_write() {
    _trap
    sleep ${DEMO_SPEED-$SPEED}
    sleep ${DEMO_SPEED-$SPEED}

    output=$@

    for (( i=0; i<${#output}; i++ )); do
        echo -n "${output:$i:1}"
        sleep ${DEMO_SPEED-$SPEED}
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
    DEMO_PROMPT=demo.sh
    c Mix scripted and live demos with ease
    DEMO_SPEED='0.025'
    c 'Comments and commands appear to be "typed" which offers time'
    c 'for presenters to talk through what is happening as it happens'
    c
    DEMO_SPEED=0
    c USAGE
    c Include demo.sh in your demo script
    c '  source demo.sh'
    c
    c COMMANDS
    c '  c     - output a comment'
    c '  x     - output a command, execute, and output the result'
    c '  hold  - hold for input'
    c '  shell - start a new shell for live demo purposes'
    c
    c http://github.com/jesselang/demo.sh
fi


