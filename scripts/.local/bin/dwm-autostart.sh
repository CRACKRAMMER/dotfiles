#!/bin/bash

/bin/bash dwm-status.sh &
/bin/bash wp-autochange.sh &

picom -o 0.95 -i 0.88 --detect-rounded-corners --vsync --blur-background-fixed -f -D 5 -c -b
#picom -b

export _JAVA_AWT_WM_NONREPARENTING=1
export  AWT_TOOLKIT=MToolkit
wmname LG3D

export GTK_IM_MODULE="fcitx"
export QT_IM_MODULE="fcitx"
export XMODIFIERS="@im=fcitx"

fcitx5 &

/bin/bash tap-to-click.sh &
/bin/bash inverse-scroll.sh &
#/bin/bash setxmodmap-colemak.sh &
nm-applet --no-agent &
xfce4-power-manager --no-daemon &
#xfce4-volumed-pulse &
#/bin/bash run-mailsync.sh &
dwm-autostart-wait.sh &

if test -e ~/.dwm-custom.sh; then
    . ~/.dwm-custom.sh &
fi
