#!/usr/bin/env bash
set -euo pipefail

step=5

if command -v pactl >/dev/null 2>&1; then
    audio_backend=pactl
elif command -v wpctl >/dev/null 2>&1; then
    audio_backend=wpctl
else
    printf 'Volume control requires pactl or wpctl.\n' >&2
    exit 1
fi

get_volume() {
    if [[ $audio_backend == pactl ]]; then
        pactl get-sink-volume @DEFAULT_SINK@ | awk 'match($0, /[0-9]+%/) { print substr($0, RSTART, RLENGTH - 1); exit }'
    else
        wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{ printf "%.0f\n", $2 * 100 }'
    fi
}

set_volume() {
    if [[ $audio_backend == pactl ]]; then
        pactl set-sink-volume @DEFAULT_SINK@ "$1%"
    else
        wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ "$1%"
    fi
}

choose() {
    if command -v wofi >/dev/null 2>&1; then
        wofi --dmenu --prompt volume
    elif command -v rofi >/dev/null 2>&1; then
        rofi -dmenu -p volume
    elif command -v fuzzel >/dev/null 2>&1; then
        fuzzel --dmenu --prompt 'volume> '
    else
        printf 'Volume menu requires wofi, rofi, or fuzzel.\n' >&2
        return 1
    fi
}

case ${1:-menu} in
    up)
        current=$(get_volume)
        next=$(( (current / step + 1) * step ))
        (( next > 100 )) && next=100
        set_volume "$next"
        ;;
    down)
        current=$(get_volume)
        next=$(( current % step == 0 ? current - step : current - current % step ))
        (( next < 0 )) && next=0
        set_volume "$next"
        ;;
    toggle)
        if [[ $audio_backend == pactl ]]; then
            pactl set-sink-mute @DEFAULT_SINK@ toggle
        else
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        fi
        ;;
    menu)
        action=$(printf 'switch\nvolume\n' | choose) || exit 1
        case $action in
            switch)
                [[ $audio_backend == pactl ]] || { printf 'Sink switching requires pactl.\n' >&2; exit 1; }
                sink=$(pactl list short sinks | awk '{ print $2 }' | choose) || exit 1
                [[ -n $sink ]] && pactl set-default-sink "$sink"
                ;;
            volume)
                value=$(seq 0 "$step" 100 | choose) || exit 1
                [[ -n $value ]] && set_volume "$value"
                ;;
        esac
        ;;
    *)
        printf 'Usage: %s [up|down|toggle|menu]\n' "$0" >&2
        exit 2
        ;;
esac

if command -v notify-send >/dev/null 2>&1; then
    notify-send -- "Volume: $(get_volume)%" || true
fi
