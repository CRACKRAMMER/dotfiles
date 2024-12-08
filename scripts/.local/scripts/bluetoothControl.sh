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

device_list=`bluetoothctl devices`
if test -n "$device_list"
then
    device_name=`printf "$device_list" | eval $switch_driver`

    if test -n "$device_name"
    then
        device_id=`printf "$device_name" | awk '{print $2}'`
        comm=`printf "connect\ndisconnect\n" | eval $switch_driver`
        if test -n "$comm"
        then
            eval bluetoothctl $comm $device_id
            notify-send -- "$device_name $comm $device_name"
        fi
    fi
fi


