#!/bin/bash

/bin/bash ~/.dwm-scripts/dwm-status.sh &
/bin/bash ~/.dwm-scripts/wp-autochange.sh &

picom -o 0.95 -i 0.88 --detect-rounded-corners --vsync --blur-background-fixed -f -D 5 -c -b
#picom -b

export _JAVA_AWT_WM_NONREPARENTING=1
export  AWT_TOOLKIT=MToolkit
wmname LG3D

export GTK_IM_MODULE="fcitx"
export QT_IM_MODULE="fcitx"
export XMODIFIERS="@im=fcitx"

fcitx5 &

/bin/bash ~/.dwm-scripts/tap-to-click.sh &
/bin/bash ~/.dwm-scripts/inverse-scroll.sh &
#/bin/bash ~/.dwm-scripts/setxmodmap-colemak.sh &
nm-applet --no-agent &
xfce4-power-manager --no-daemon &
#xfce4-volumed-pulse &
#/bin/bash ~/.dwm-scripts/run-mailsync.sh &
~/.dwm-scripts/autostart_wait.sh &

if test -e ~/.dwm-custom.sh; then
    . ~/.dwm-custom.sh &
fi
