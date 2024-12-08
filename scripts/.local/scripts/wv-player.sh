#!/bin/bash
while test 1 -lt `ps aux | grep xwinwrap | wc -l`
do
    killall xwinwrap
done

fifo=/tmp/$(basename $0 | cut -d'.' -f1)
if test ! -e $fifo
then
    mkfifo $fifo
fi

codes="-name *.mp4 -o -name *.avi -o -name *.wmv -o -name *.mkv -o -name *.webm"

video=$(sort --random-sort <<< $(find ~/Pictures/Wallpaper/Videos -type f `echo $codes`) | head -n 1)

xwinwrap -fs -nf -ni -ov -- mplayer -nosound -shuffle -slave -input file=$fifo -wid WID -loop 0 -nolirc $video
