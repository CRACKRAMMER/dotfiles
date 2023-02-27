#/bin/bash

file_name=$(basename $0 | cut -d'.' -f1)
dirpath=(~/Pictures/Wallpaper/Images/)

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

if test "$#" -eq 2
then
    dirpath=$1
    shift
fi

cd $dirpath && find . -maxdepth 1 -type l -delete || exit 1

if test -n "$1"
then
    [[ -e "$1" ]] && ln -sf $1/* . || exit 1
else
    find . -type f | xargs -I{} ln -sf {} . 
fi
