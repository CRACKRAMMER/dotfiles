#!/bin/bash

file_name=$(basename $0 | cut -d'.' -f1)
script_path=$(dirname $0)
script_list=$(ls $script_path/*Control.sh)

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

comm=$(printf "$script_list" | xargs -I{} basename "{}" | eval $switch_driver)
eval $comm
