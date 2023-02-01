#/bin/bash

dirpath=(~/Pictures/Wallpaper/Images/)
if test "$#" -eq 2
then
    dirpath=$1
    shift
fi

cd $dirpath && find . -type l -delete || exit 1

if test -n "$1"
then
    [[ -e "$1" ]] && ln -sf $1/* . || exit 1
else
    find . -type f | xargs -I{} ln -sf {} . 
fi
