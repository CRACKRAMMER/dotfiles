#!/bin/bash

fifo=/tmp/$(basename $0 | cut -d'.' -f1)

if test ! -e $fifo
then
    mkfifo $fifo
fi

flag=0
if test ! -z $1
then
    idlist=$(cat $fifo)
    for id in $idlist
    do
        flag=$(cut -b 1 <<< $id)
        kill -9 $(cut -b 2- <<< $id)
    done
    if test $flag -eq 0
    then
        flag=1
    else
        flag=0
    fi
fi

echo $flag$$ > $fifo &

execute="dwm-status-toggle.sh"

if test $flag -eq 0
then
    execute="dwm-status-refresh.sh; sleep 1"
fi

while true
do
    eval $execute
done
