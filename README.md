# demo.sh

Script the boring stuff in your demo, leaving room for doing the nail-biting
parts of your demo live and unedited.

Comments and commands appear to be "typed", freeing the presenter to talk
about what is happening as it happens. Typing speed is configurable.
SIGINT (`Ctrl-C`) works as you'd expect, and SIGQUIT (`Ctrl-\`) will
"shell out" at any point during the scripted demo for those impromptu live
tweaks.

## Basic example

```bash
#!/bin/bash

source path/to/demo.sh

c 'Write things here that you want to appear "typed" as comments.'
c Remember to double-quote lines that include double or single quotes.
c "You'll be sad if you forget. Space out this wall of text with an 'x'."
x

# NOTE: this comment won't appear in your demo

c 'Using x with a command will appear to "type" the command, then execute it'
c What time is it?
x date
c "It's time for lunch!"
x

c "Let's sleep 2 seconds, and clear the screen"
sleep 2
clear

c 'You can choose good points in the demo to "hold" moving on to finish'
c explaining, or answer questions. Pressing any key will continue.
hold

c You can also plan to go into a live shell during the demo.
c Exit the shell to continue the scripted demo.
shell

x
c "Now you've seen the basic use of demo.sh. Thanks for checking it out!"
```
