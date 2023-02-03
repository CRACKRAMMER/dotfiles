#!/bin/bash

volume=$(pamixer --get-volume)
step=5

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
        exit 1
esac

notify-send -- "volume $(pamixer --get-volume)"
