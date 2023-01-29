#!/bin/bash
#
# This script toggles all monitor outputs if something is connected
#

# all available outputs
OUTPUTS=$(xrandr |awk '$2 ~ /^connected/ {print $1}')

EXECUTE=""

for CURRENT in $OUTPUTS
do
    EXECUTE+="--output $CURRENT --auto "
done

xrandr $EXECUTE
