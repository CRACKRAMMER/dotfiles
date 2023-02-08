#!/bin/bash

file_name=`basename $0 | cut -d'.' -f1`
volume=$(pamixer --get-volume)
step=5

case "$XDG_SESSION_TYPE" in 
    "wayland")
        switch_driver="wofi -W 500 -H 500 -d -n -i --prompt $file_name"
        ;;
    "x11")
        switch_driver="rofi -normal-window -dmenu -p $file_name"
        ;;
    *)
        exit 1
esac

case "$1" in
    "up")
        value=$[volume-volume%step+step]
        [[ $value -ge 100 ]] && pamixer --set-volume 100 || pamixer --set-volume $value
        ;;
    "down")
        value=$[volume-volume%step-!(volume%step)*step]
        [[ $value -le $step ]] && pamixer --set-volume $step || pamixer --set-volume $value
        ;;
    "toggle")
        pamixer -t
        ;;
    *)
        value=`seq 0 $step 100 | xargs -I{} printf '{}%%\n' | eval $switch_driver | cut -d'%' -f1`
        [[ -n $value ]] && pamixer --set-volume $value
esac

notify-send -- "volume $(pamixer --get-volume)"
