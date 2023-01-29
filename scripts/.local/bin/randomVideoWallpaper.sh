#!/bin/bash

kill `ps aux | grep -v -e grep -e $$ | grep randomWallpaper.sh | awk '{print $2}' | xargs echo` 2> /dev/null

mpvpaper -vs -o "no-audio loop" `hyprctl monitors | head -n1 | cut -d' ' -f2` "`ls -d ~/Pictures/Wallpaper/Videos/* | sort -R | head -n1`" &

sleep 1
kill `ps aux | grep -v -e grep -e $$ -e $! | grep -e randomVideoWallpaper.sh -e mpvpaper | awk '{print $2}' | xargs echo` 2> /dev/null

while true;
do
    sleep 1h 
done
