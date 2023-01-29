#!/bin/bash

light=$(xbacklight -get | sed 's/\.[0-9]*//g')
if test $[$light-10] -le 10
then
    xbacklight -set 10
else
    xbacklight -set $[$light-10]
fi
