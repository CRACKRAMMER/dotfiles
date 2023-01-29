#!/bin/bash
#
# This script toggles the extended monitor outputs if something is connected
#

# all available outputs
OUTPUTS=$(xrandr |awk '$2 ~ /^connected/ {print $1}')

# your notebook LVDS monitor
DEFAULT_OUTPUT=$(xrandr | awk '$3 ~ /^primary/ {print $1}')

# get info from xrandr
XRANDR=`xrandr | grep ' connected'`

EXECUTE=""

for CURRENT in $OUTPUTS
do
    if [[ $CURRENT == $DEFAULT_OUTPUT ]]
    then
        continue
    fi

    if [[ $XRANDR == *$CURRENT\ connected\ \(* ]] # is disabled
    then
            EXECUTE+="--output $CURRENT --auto "
    else
            EXECUTE+="--output $CURRENT --off "
    fi
done

xrandr --output $DEFAULT_OUTPUT --auto $EXECUTE
