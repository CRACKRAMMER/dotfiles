#!/bin/zsh
steam_user=$1

if test `ps aux | grep steam.sh | wc -l` -gt 1
then
    echo "Please exit steam first"
    exit 1
fi

if test ! -d ~/Games/SteamUser/$steam_user/
then
    echo "$steam_user not found"
    exit 1
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
