#!/bin/zsh

file_name=$(basename $0 | cut -d'.' -f1)
games_path=(~/Games/SteamUser)

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

if test -n "$1"
then
    steam_user=$1
else
    steam_user=$(ls `echo $games_path` | eval $switch_driver)
fi

if test -z "$steam_user" -a ! -d "$games_path/$steam_user/"
then
    echo "$steam_user not found"
    exit 1
fi

if test `ps aux | grep steam.sh | wc -l` -gt 1
then
    echo "Please exit steam first"
    exit 2
fi


rm ~/.steam/bin32
rm ~/.steam/bin64
rm ~/.steam/root
rm ~/.steam/steam
rm ~/.steam/sdk32
rm ~/.steam/sdk64

ln -sf ~/Games/SteamUser/$steam_user/Steam/ubuntu12_32 ~/.steam/bin32
ln -sf ~/Games/SteamUser/$steam_user/Steam/ubuntu12_64 ~/.steam/bin64
ln -sf ~/Games/SteamUser/$steam_user/Steam ~/.steam/root
ln -sf ~/Games/SteamUser/$steam_user/Steam ~/.steam/steam
ln -sf ~/Games/SteamUser/$steam_user/Steam/linux32 ~/.steam/sdk32
ln -sf ~/Games/SteamUser/$steam_user/Steam/linux64 ~/.steam/sdk64

rm ~/.local/share/Steam
rm ~/.steam/registry.vdf
rm ~/.steam/steam.token

ln -sf ~/Games/SteamUser/$steam_user/Steam ~/.local/share/Steam
ln -sf ~/Games/SteamUser/$steam_user/registry.vdf ~/.steam/registry.vdf
ln -sf ~/Games/SteamUser/$steam_user/steam.token ~/.steam/steam.token
