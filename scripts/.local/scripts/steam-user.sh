#! /bin/bash

users_dir='/home/xiechengan/Games/SteamUser'
before_operation='pacmd set-default-sink 1; pamixer --set-volume 40;'


while getopts ":c:s:" opt; do
  case $opt in
    s)
        if test -e "/run/user/`id -u $OPTARG`"
        then
            script -q -c "su -c \"source ~/.zshrc; pulsemixer\" $OPTARG" /dev/null
        else
            echo "launch steam please"
        fi
        exit
        ;;
    c)
        $before_operation=$OPTARG
        ;;
    \?)
        echo "Invalid option: -$OPTARG"
        ;;
  esac
done

shift $(($OPTIND - 1))

# echo remaining parameters=[$*]
# echo \$1=[$1]
# echo \$2=[$2]

for user in `ls $users_dir`
do
    if [[ $user = $1 && `stat -c %U $users_dir/$user` = $1 ]]
    then
        xhost + 1>/dev/null
        user_run="/tmp/steam_$user"
        ls $user_run 2>/dev/null && rm $user_run
        mkfifo $user_run
        { sleep 1; echo 1; } | script -q -c "ssh $user@127.0.0.1 \"$before_operation cat $user_run\"" /dev/null 1>/dev/null &
        export DRI_PRIME=1
        export XDG_RUNTIME_DIR=/run/user/`id -u $user`
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/`id -u $user`/bus
        { sleep 1; echo 1; } | script -q -c "su -c steam-native $user" /dev/null
        echo 1 > $user_run
        rm $user_run
        xhost - 1>/dev/null
    fi
done
