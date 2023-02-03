#!/bin/bash

light=$(light -G | cut -d'.' -f1)
step=10

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
        exit 1
esac

notify-send -- "brightness $(light -G | cut -d'.' -f1)"
