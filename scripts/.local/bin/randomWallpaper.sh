sleep 1
swww init
while true;
do
  ls -d ~/Pictures/Wallpaper/Images/* | sort -R | while read file;
  do
    swww img "$file"
    sleep 30m
  done
done
