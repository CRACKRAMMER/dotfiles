#!/bin/bash

light=$(xbacklight -get | sed 's/\.[0-9]*//g')
if test $[$light+10] -ge 100
then
    xbacklight -set 100
else
    xbacklight -set $[$light+10]
fi
