#!/bin/bash

source demo.sh

DEMO_SPEED=40
_calc_write_delay
time _write \
    This is two hundred characters. It should take one minute to print. This is two hundred characters. It should take one minute to print.  This is two hundred characters. It should take one minute to...

DEMO_SPEED=80
_calc_write_delay
time _write \
    This is two hundred characters. It should take 30 seconds to print. This is two hundred characters. It should take 30 seconds to print.  This is two hundred characters. It should take 30 seconds to..
