#!/bin/bash

file_name=`basename $0 | cut -d'.' -f1`

case "$XDG_SESSION_TYPE" in 
    "wayland")
        switch_driver="wofi -d -n --prompt $file_name"
        ;;
    "x11")
        switch_driver="rofi -normal-window -dmenu -p $file_name"
        ;;
    *)
        exit 1
esac

comm=`printf "play-pause\nplay\npause\nnext\nprevious\nposition\nvolume\n" | eval $switch_driver`

if test -n "$comm"
then
    player_name=`playerctl --list-all | eval $switch_driver`

    case "$comm" in 
        "position")
            value=`seq 0 10 100 | xargs -I{} printf '{}%%\n' | eval $switch_driver | cut -d'%' -f1`
            value=$(echo "scale=2;$(playerctl --player=$player_name metadata mpris:length)/100000000*$value" | bc)
            ;;
        "volume")
            value=`seq 100 -10 0 | xargs -I{} printf '{}%%\n' | eval $switch_driver | cut -d'%' -f1`
            value=$(echo "scale=2;$value/100" | bc)
            ;;
    esac

    if test -n "$player_name"
    then
        playerctl $comm $value --player="$player_name"
    fi
fi
