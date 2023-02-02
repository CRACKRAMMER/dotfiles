#!/bin/bash

case "$XDG_SESSION_TYPE" in
    "wayland")
        comm="wl-paste -p"
        ;;
    "x11")
        comm="xclip -o"
        ;;
    *)
        exit 1
esac

transout=$(crow -b -t zh-CN -- "$(eval $comm)")
notify-send -- "$transout"
