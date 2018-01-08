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
_clr_muted='\033[38;5;242m'
_clr_hold='\033[38;5;1m'
_clr_live='\033[38;5;2m'
_clr_normal='\033[m'

# these variables can be overwritten
# default speed
DEMO_SPEED=${DEMO_SPEED:-90}
# used to convert words per minute to characters per minute
DEMO_SPEED_WORD_LEN=${DEMO_SPEED_WORD_LEN:-5}

# speed variation while "typing" to make it seem natural
DEMO_SPEED_VARY_MAX=1.4
DEMO_SPEED_VARY_MIN=0.8

# default prompt text
DEMO_TXT=${DEMO_TXT:-demo}
DEMO_TXT_HOLD=${DEMO_TXT_HOLD:-hold}
DEMO_TXT_LIVE=${DEMO_TXT_LIVE:-live}

# default colors
DEMO_CLR=${DEMO_CLR:-$_clr_muted}
DEMO_CLR_HOLD=${DEMO_CLR_HOLD:-$_clr_hold}
DEMO_CLR_LIVE=${DEMO_CLR_LIVE:-$_clr_live}

_set_title() {
    echo -en "\033]0;${1:-${DEMO_TITLE:-$DEMO_TXT}}\007"
}
_prompt() {
    _clear_line
    echo -en "${@:-${DEMO_PS1:-"${DEMO_CLR}${DEMO_TXT}>${_clr_normal} "}}"
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

        # recalculate write speed every 2 "words"
        # awk reseeds every second, no use recalculating more often
        if [[ $(( (i + 1) % (DEMO_SPEED_WORD_LEN * 2) )) -eq 0 ]]; then
            _calc_write_delay
        fi
    done

    echo
}

# intentionally overrides the 'clear' builtin to print the prompt afterward
clear() {
    _set_title clear
    command clear
    _set_title
    _prompt
}

_shell_out() {
    # reset the output counter if we interrupted _write()
    i=-1
    # trapping SIGQUIT prints a "\Quit" followed by a new line, clean that up
    echo -en '\033[1A' # move up 1 line
    _clear_line
    live ""
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
        # / (rand() ...     # speed variance
        _write_delay=$(awk "
            BEGIN {
                srand();                                            \
                print (                                             \
                    1 / (($DEMO_SPEED * $DEMO_SPEED_WORD_LEN) / 60) \
                    / ${1:-1}                                       \
                    / (rand()                                       \
                        * ($DEMO_SPEED_VARY_MAX                     \
                            - $DEMO_SPEED_VARY_MIN)                 \
                        + $DEMO_SPEED_VARY_MIN                      \
                    )                                               \
                )
            }
        ")
    fi
}

c() {
    trap - EXIT
    _set_title
    _calc_write_delay 2 # comments should go faster; they are easier to grok
    _write "# $*"
    _prompt
    trap _clear_line EXIT
}

x() {
    trap - EXIT
    _set_title
    _calc_write_delay
    _write "$@"
    _set_title "$@"
    eval "$@"
    _set_title
    _prompt
    trap _clear_line EXIT
}

hold() {
    trap - EXIT
    _set_title ${@:-$DEMO_TXT_HOLD}
    _prompt "${DEMO_PS1_HOLD:-"${DEMO_CLR_HOLD}-- ${@:-$DEMO_TXT_HOLD} --${_clr_normal} "}"
    read -rsn 1
    _set_title
    _prompt
    trap _clear_line EXIT
}

# shellcheck disable=SC2120
live() {
    trap - EXIT
    _set_title ${@:-$DEMO_TXT_LIVE}
    _clear_line
    PS1="${DEMO_PS1_LIVE:-"${DEMO_CLR_LIVE}${@:-$DEMO_TXT_LIVE}>${_clr_normal} "}" \
        bash --noprofile --norc
    echo -en '\033[1A' # move up 1 line
    _set_title
    _prompt
    trap _clear_line EXIT
}

demo_main() {
    DEMO_TXT=demo.sh
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
    c '  c     "<text>"  - output <text> as a comment'
    c '  x    ["<text>"] - output a command, execute, and output the result'
    c '  hold ["<text>"] - hold for input using <text> as the prompt'
    c '  live ["<text>"] - start a new live shell using <text> as the prompt'
    c
    c http://github.com/jesselang/demo.sh
}

if [[ "$0" = "${BASH_SOURCE[0]}" ]]; then
    demo_main
fi
