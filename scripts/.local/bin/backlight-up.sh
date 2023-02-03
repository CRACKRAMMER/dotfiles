#!/bin/bash

light=$(light -G | cut -d'.' -f1)
if test $[$light+10] -ge 100
then
    light -S 100
else
    light -S $[$light+10]
fi
