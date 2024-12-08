#!/bin/bash

print_mem(){
	#memfree=$(($(grep -m1 'MemAvailable:' /proc/meminfo | awk '{print $2}') / 1024))
        memdata=$(free -m)
        memavailable=$(echo "$memdata" | awk 'NR==2 {print $7}')
	memused=$(echo "$memdata" | awk 'NR==2 {print $3}')
	echo -e "$memused/$memavailable"
}

print_disk(){
    df -h | awk '$6 ~ "^/$"  {print $4}'
}

print_cpu(){
    echo -e $(sar 1 1 | awk 'NR == 5 {print $3+$4+$5}')
}

print_io(){
    echo -e $(iostat -d -m | awk 'BEGIN {read=0; write=0}; NR>=4 {read+=$3; write+=$4}; END {print read, write}')
}

io=$(print_io)
io_read=$(awk '{print $1}' <<< $io)
io_write=$(awk '{print $2}' <<< $io)

xsetroot -name "[ CPU $(print_cpu)% ] [ MEMORY $(print_mem)M ] [ DISK $(print_disk) ] [ READ $io_read M/s, WRITE $io_write M/s ]"

exit 0
