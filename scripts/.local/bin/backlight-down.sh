#!/bin/bash

light=$(light -G | cut -d'.' -f1)
if test $[$light-10] -le 10
then
    light -S 10
else
    light -S $[$light-10]
fi
