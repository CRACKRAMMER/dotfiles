#!/bin/bash
if test -z $1
then
    while test 1 -lt `ps aux | grep xwinwrap | wc -l`
    do
        killall xwinwrap
    done
fi

feh --recursive --randomize --bg-fill ~/Pictures/Wallpaper/Images/
#feh --recursive --randomize --bg-fill ~/Pictures/wallpapers/view
