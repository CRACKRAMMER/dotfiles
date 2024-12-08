#!/bin/bash
process=`sh -c "ps aux | grep -v -e grep -e $$ | grep $(basename $0)"`
process=`echo $process | awk '{print $2}'`
if test -n "$process"
then
    kill $process
else
    while true
    do
        xdotool click 1
        notify-send 'on click'
        sleep 0.1
    done
fi
