#!/usr/bin/env bash

echo -en hello | grep -q '-en' -
_echo_en=$?

if [ $_echo_en -eq 0 ]; then
    echo "error: demo.sh requires a bash-compatible shell; your script uses:" >&2
    head -1 "${0}" >&2
    exit 1
fi
unset _echo_en

command -v awk &>/dev/null || {
    echo 'error: awk is required for decimal arithmetic, but not found' >&2
    exit 1
}

# colors - https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
_clr_muted='\e[38;5;242m'
_clr_hold='\e[38;5;1m'
_clr_live='\e[38;5;2m'
_clr_normal='\e[m'

# these variables can be overwritten
# default speed
DEMO_SPEED=${DEMO_SPEED:-90}
# used to convert words per minute to characters per minute
DEMO_SPEED_WORD_LEN=${DEMO_SPEED_WORD_LEN:-5}

# default prompt text
DEMO_TXT=${DEMO_TXT:-demo}
DEMO_TXT_HOLD=${DEMO_TXT_HOLD:-hold}
DEMO_TXT_LIVE=${DEMO_TXT_LIVE:-live}

# default colors
DEMO_CLR=${DEMO_CLR:-$_clr_muted}
DEMO_CLR_HOLD=${DEMO_CLR_HOLD:-$_clr_hold}
DEMO_CLR_LIVE=${DEMO_CLR_LIVE:-$_clr_live}

# default prompts
DEMO_PS1="${DEMO_CLR}${DEMO_TXT}>${_clr_normal} "
DEMO_PS1_HOLD="${DEMO_CLR_HOLD}-- ${DEMO_TXT_HOLD} --${_clr_normal} "
DEMO_PS1_LIVE="${DEMO_CLR_LIVE}${DEMO_TXT_LIVE}>${_clr_normal} "

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
    if [[ ${_write_delay} != 0 ]]; then
        # shellcheck disable=SC2034
        for _sleep in {1..6}; do
            sleep "${_write_delay}"
        done
    fi

    output=$*

    for (( i=0; i<${#output}; i++ )); do
        echo -n "${output:$i:1}"
        sleep "${_write_delay}"
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

_calc_write_delay() {
    if [[ $DEMO_SPEED -le 0 ]]; then
        _write_delay=0
    else
        # DEMO_SPEED is words per minute
        # 1 /                # one second, divided by...
        # (
        #   ($DEMO_SPEED * $DEMO_SPEED_WORD_LEN) # words/minute to chars/minute
        #   / 60            # chars/minute into chars/second
        # )
        # / ${1:-1}         # multiplier used to type comments faster; which
        #                   # are more quickly digestible than commands
        _write_delay=$(awk -e "
            BEGIN {
                print (                                             \
                    1 / (($DEMO_SPEED * $DEMO_SPEED_WORD_LEN) / 60) \
                    / ${1:-1}                                       \
                )
            }
        ")
    fi
}

c() {
    trap - EXIT
    _calc_write_delay 2 # comments should go faster; they are easier to grok
    _write "# $*"
    _prompt
    trap _clear_line EXIT
}

x() {
    trap - EXIT
    _calc_write_delay
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

demo_main() {
    # set _demo_main=true to avoid an endless loop
    local _demo_main=true
    DEMO_TXT=demo.sh
    # shellcheck disable=SC1090
    source "${BASH_SOURCE[0]}"
    c Mix scripted and live demos with ease
    DEMO_SPEED=150
    c 'Comments and commands appear to be "typed" which offers time'
    c 'for presenters to talk through what is happening as it happens'
    c
    DEMO_SPEED=0
    c USAGE
    c Include demo.sh in your demo script
    c '  source demo.sh'
    c
    c COMMANDS
    c '  c "<text>" - output <text> as a comment'
    c '  x "<text>" - output a command, execute, and output the result'
    c '  hold  - hold for input'
    c '  shell - start a new shell for live demo purposes'
    c
    c http://github.com/jesselang/demo.sh
}

if [[ "$0" = "${BASH_SOURCE[0]}" ]] && [[ -z $_demo_main ]]; then
    demo_main
fi
