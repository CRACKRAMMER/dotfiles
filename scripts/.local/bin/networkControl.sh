#!/bin/bash

file_name=`basename $0 | cut -d'.' -f1`

case "$XDG_SESSION_TYPE" in 
    "wayland")
        switch_driver="wofi -W 500 -H 500 -d -n -i --prompt $file_name"
        ;;
    "x11")
        switch_driver="rofi -dmenu -p $file_name"
        ;;
    *)
        exit 1
esac

network_list=`nmcli -t connection show | cut -d':' -f1`
if test -n "$network_list"
then
    network_name=`printf "$network_list" | eval $switch_driver`

    if test -n "$network_name"
    then
        comm=`printf "up\ndown\n" | eval $switch_driver`
        if test -n "$comm"
        then
            nmcli connection $comm "$network_name"
            notify-send -- "$network_name $comm"
        fi
    fi
fi


