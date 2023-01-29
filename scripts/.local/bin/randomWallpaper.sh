#/bin/bash

kill `ps aux | grep -v -e grep -e $$ | grep randomWallpaper.sh | awk '{print $2}' | xargs echo` 2> /dev/null

swww init 2> /dev/null

swww img "`ls -d ~/Pictures/Wallpaper/Images/* | sort -R | head -n1`"
kill `ps aux | grep -v -e grep -e $$ | grep -e randomVideoWallpaper.sh -e mpvpaper | awk '{print $2}' | xargs echo` 2> /dev/null

while true;
do
    sleep 15m
    swww img "`ls -d ~/Pictures/Wallpaper/Images/* | sort -R | head -n1`"
  # ls -d ~/Pictures/Wallpaper/Images/* | sort -R | while read file;
  # do
  #   swww img "$file"
  #   sleep 15m
  # done
done
