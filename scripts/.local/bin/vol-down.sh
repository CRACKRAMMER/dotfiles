#!/bin/bash

volume=$(pamixer --get-volume)
if [ $[$volume%5] -gt 0 ]; then
    pamixer --set-volume $[$volume-$volume%5]
else
    pamixer -d 5
fi
#/usr/bin/amixer -qM set Master 5%- umute
#pactl set-sink-volume @DEFAULT_SINK@ -5%
#dwm-status-refresh.sh
