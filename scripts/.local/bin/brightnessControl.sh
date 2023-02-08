#!/bin/bash

file_name=`basename $0 | cut -d'.' -f1`
light=$(light -G | cut -d'.' -f1)
step=5

case "$XDG_SESSION_TYPE" in 
    "wayland")
        switch_driver="wofi -W 500 -H 500 -d -n -i --prompt $file_name"
        ;;
    "x11")
        switch_driver="rofi -normal-window -dmenu -p $file_name"
        ;;
esac

case "$1" in
    "up")
        value=$[light-light%step+step]
        [[ $value -ge 100 ]] && light -S 100 || light -S $value
        ;;
    "down")
        value=$[light-light%step-!(light%step)*step]
        [[ $value -le $step ]] && light -S $step || light -S $value
        ;;
    *)
        if test -n "$switch_driver"
        then
            value=`seq 0 $step 100 | xargs -I{} printf '{}%%\n' | eval $switch_driver | cut -d'%' -f1`
            [[ -n $value ]] && light -S $value
        else
            exit 1
        fi
esac

notify-send -- "brightness $(light -G | cut -d'.' -f1)"
