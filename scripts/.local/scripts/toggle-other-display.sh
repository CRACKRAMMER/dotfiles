#!/bin/bash
#
# This script toggles all other monitor outputs if something is connected
#

# all available outputs
OUTPUTS=$(xrandr |awk '$2 ~ /^connected/ {print $1}')

# your notebook primary monitor
DEFAULT_OUTPUT=$(xrandr | awk '$3 ~ /^primary/ {print $1}')

# get info from xrandr
XRANDR=`xrandr`

EXECUTE=""

for CURRENT in $OUTPUTS
do
    if [[ $CURRENT == $DEFAULT_OUTPUT ]]
    then
            if [[ $XRANDR == *$CURRENT\ connected\ \(* ]] # is disabled
            then
                EXECUTE+="--output $CURRENT --auto "
            else
                EXECUTE+="--output $CURRENT --off "
            fi
    else
        EXECUTE+="--output $CURRENT --auto "
    fi

done

xrandr $EXECUTE
