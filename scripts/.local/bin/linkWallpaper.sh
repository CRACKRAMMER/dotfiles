#/bin/bash

file_name=$(basename $0 | cut -d'.' -f1)
dirpath=~/Pictures/Wallpaper

cd $dirpath

case "$XDG_SESSION_TYPE" in 
    "wayland")
        switch_driver="wofi -W 500 -H 500 -d -n -i --prompt $file_name"
        ;;
    "x11")
        switch_driver="rofi -dmenu -p $file_name"
        ;;
    *)
        exit 1
esac

if test "$#" -eq 0
then
    dirpath=$(ls * -d | eval $switch_driver)
elif test "$#" -le 2
then
    dirpath=Images
else
    dirpath=$1
    shift
fi

if test -n "$dirpath"
then
    cd $dirpath && find . -maxdepth 1 -type l -delete || exit 1
else
    exit 2
fi

if test -n "$1"
then
    $dirpath=$1
    shift
else
    dirpath=$(find * -type d | eval $switch_driver)
fi

[[ -e "$dirpath" ]] && ln -sf $dirpath/* . || exit 1
