#!/usr/bin/env bash

echo -en hello | grep -q '-en' -
_echo_en=$?

if [ $_echo_en -eq 0 ]; then
    echo "error: demo.sh requires a bash-compatible shell; your script uses:" >&2
    head -1 "${0}" >&2
    exit 1
fi
unset _echo_en

# colors - https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
_clr_muted='\e[38;5;242m'
_clr_hold='\e[38;5;1m'
_clr_live='\e[38;5;2m'
_clr_normal='\e[m'

# these variables can be overwritten
# default speed
DEMO_SPEED=${DEMO_SPEED:-0.1}

# default prompt text
DEMO_PROMPT=${DEMO_PROMPT:-demo}
DEMO_PROMPT_HOLD=${DEMO_PROMPT_HOLD:-hold}
DEMO_PROMPT_LIVE=${DEMO_PROMPT_LIVE:-live}

# default colors
DEMO_CLR_PROMPT=${DEMO_PROMPT_CLR:-$_clr_muted}
DEMO_CLR_HOLD=${DEMO_CLR_HOLD:-$_clr_hold}
DEMO_CLR_LIVE=${DEMO_CLR_LIVE:-$_clr_live}

# default prompts
DEMO_PS1="${DEMO_CLR_PROMPT}${DEMO_PROMPT}>${_clr_normal} "
DEMO_PS1_HOLD="${DEMO_CLR_HOLD}-- ${DEMO_PROMPT_HOLD} --${_clr_normal} "
DEMO_PS1_LIVE="${DEMO_CLR_LIVE}${DEMO_PROMPT_LIVE}>${_clr_normal} "

_prompt() {
    _clear_line
    case "$1" in
        hold)
            echo -en "${DEMO_PS1_HOLD}"
            ;;
        '')
            echo -en "${DEMO_PS1}"
            ;;
        *)
            echo "error: _prompt() doesn't know how to handle '$1'" >&2
            exit 1
            ;;
    esac
}

# ANSI escape codes - http://www.climagic.org/mirrors/VT100_Escape_Codes.html
_clear_line() {
    echo -en '\r'      # carriage return
    echo -en '\033[2K' # clear entire line
}

_write() {
    _prompt
    # shellcheck disable=SC2034
    for _sleep in {1..6}; do
        sleep "${DEMO_SPEED}"
    done

    output=$*

    for (( i=0; i<${#output}; i++ )); do
        echo -n "${output:$i:1}"
        sleep "${DEMO_SPEED}"
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
    PS1="${DEMO_PS1_LIVE}" bash --noprofile --norc
    echo -en '\033[1A' # move up 1 line
    _prompt
    trap _clear_line EXIT
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
    DEMO_PROMPT=demo.sh
    c Mix scripted and live demos with ease
    DEMO_SPEED=${DEMO_SPEED:-0.025}
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


