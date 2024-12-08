#!/bin/bash

volume=$(pamixer --get-volume)
pamixer --set-volume $[$volume-$volume%5+5]
#/usr/bin/amixer -qM set Master 5%+ umute
#pactl set-sink-volume @DEFAULT_SINK@ +5%
#dwm-status-refresh.sh
