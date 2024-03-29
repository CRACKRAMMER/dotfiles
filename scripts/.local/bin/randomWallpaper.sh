#/bin/bash

# kill `ps aux | grep -v -e grep -e $$ | grep randomWallpaper.sh | awk '{print $2}' | xargs echo` 2> /dev/null
kill `ps aux | grep -v -e grep -e $$ | grep -e randomVideoWallpaper.sh -e mpvpaper -e xwinwrap | awk '{print $2}' | xargs echo` 2> /dev/null
[[ $? -eq 0 ]] && exit

# process=`sh -c "ps aux | grep -v -e grep -e $$ | grep $(basename $0)"`
# process=`echo $process | awk '{print $2}'`
process=$(bash -c "ps -eo pid,comm,cmd | grep -v -e grep -e ps | grep $(basename $0)")
process=`awk '$2 ~ "^(sh|bash)$" && $1 != '$$' {print $1}' <<< $process | sed 'N;s/\n/,/g'`
echo $process

if test -n "$process"
then
    kill `ps --ppid $process -o pid,ppid,comm | grep sleep | awk '{print $1}'`
    [[ $? -eq 0 ]] && exit
fi

case "$XDG_SESSION_TYPE" in 
    "wayland")
        swww init
        comm=swww
        comm_line="img --transition-type any --transition-step 255"
        ;;
    "x11")
        comm=feh
        comm_line="--recursive --randomize --bg-fill"
        ;;
    *)
        exit 1
esac

while true;
do
    files=`find -L ~/Pictures/Wallpaper/Images/ -maxdepth 1 -type f | sort -R | grep .`
    [[ $? -ne 0 ]] && break
    while read file 
    do
        eval $comm $comm_line "$file" || break
        sleep 10m
    done <<< $files
done
