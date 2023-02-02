#!/bin/bash

case "$XDG_SESSION_TYPE" in
    "wayland")
        comm=mpvpaper
        comm_line= '-vs -o "no-audio loop" `hyprctl monitors | head -n1 | cut -d' ' -f2`'
        ;;
    "x11")
        comm=xwinwrap
        comm_line='-fs -nf -ni -ov -- mpv -wid WID --loop --no-audio'
        ;;
    *)
        exit 1
esac

killall $comm
[[ "$?" -eq 0 ]] && exit

codes="-name *.mp4 -o -name *.avi -o -name *.wmv -o -name *.mkv -o -name *.webm"

while true
do
    files=`find -L ~/Pictures/Wallpaper/Videos -maxdepth 1 -type f $(echo $codes) | sort -R | grep .`
    [[ $? -ne 0 ]] && break
    while read file
    do 
        eval $comm $comm_line $file
    done <<< $files
done
