#!/usr/bin/env bash

echo -en hello | grep -q '-en' -
ECHO_EN=$?

if [ $ECHO_EN -eq 0 ]; then
    echo "error: demo.sh requires a bash-compatible shell; your script is using:" >&2
    head -1 "${0}" >&2
    exit 1
fi

SPEED='0.1'
MUTED='\033[38;5;242m'
NORMAL='\033[0m'
DEMO_PROMPT=demo

_prompt() {
    _clear_line
    echo -en "${MUTED}${1:-${DEMO_PROMPT}}>${NORMAL} "
}

_clear_line() {
    echo -en '\r'      # carriage return
    echo -en '\033[2K' # clear entire line
}

_write() {
    _prompt
    # shellcheck disable=SC2034
    for _sleep in 1 2 3 4 5 6; do
        sleep "${DEMO_SPEED:-$SPEED}"
    done

    output=$*

    for (( i=0; i<${#output}; i++ )); do
        echo -n "${output:$i:1}"
        sleep "${DEMO_SPEED-$SPEED}"
    done

    echo
}

# intentionally overrides the 'clear' builtin to print the prompt afterward
clear() {
    command clear
    _prompt
}

_shell_out() {
    # reset the output counter if we interrupted _write()
    i=-1
    # trapping SIGQUIT prints a "\Quit" followed by a new line, clean that up
    echo -en '\033[1A' # move up 1 line
    _clear_line
    shell
}
trap _shell_out QUIT

c() {
    trap - EXIT
    _write "# $*"
    _prompt
    trap _clear_line EXIT
}

x() {
    trap - EXIT
    _write "$@"
    eval "$@"
    _prompt
    trap _clear_line EXIT
}

hold() {
    trap - EXIT
    _prompt hold
    read -rsn 1
    _prompt
    trap _clear_line EXIT
}

shell() {
    trap - EXIT
    _clear_line
    PS1="${MUTED}live>${NORMAL} " bash --noprofile --norc
    echo -en '\033[1A' # move up 1 line
    _prompt
    trap _clear_line EXIT
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
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


