#!/usr/bin/env bash
case "$XDG_SESSION_TYPE" in
    "wayland")
        grim -g "$(slurp)" - | swappy -f -
        ;;
    "x11")
        maim -g $(slop -l -c 0.3,0.4,0.6,0.4) | swappy -f -
        ;;
    *)
        exit 1
esac
