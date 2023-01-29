#!/bin/sh

# A dwm_bar function to show the master volume of ALSA
# Joe Standring <git@joestandring.com>
# GNU GPLv3

# Dependencies: alsa-utils

dwm_alsa () {
    VOL=$(pamixer --get-volume)
    MUTE=$(pamixer --get-mute)
    if [[ "$MUTE" = "true" || "$VOL" -eq 0 ]]; then
        printf "MUTE"
    else
        printf "VOL %s%%" "$VOL"
    fi

#    VOL=$(amixer get Master | tail -n1 | sed -r "s/.*\[(.*)%\].*/\1/")
#    MUTE=$(amixer get Master | tail -n1 | sed -r "s/.*\[(.*)%\].*\[(.*)\].*/\2/")
#    printf "%s" "$SEP1"
#    if [ "$IDENTIFIER" = "unicode" ]; then
#        if [[ "$MUTE" = "off" || "$VOL" -eq 0 ]]; then
#            printf "🔇"
#        elif [ "$VOL" -gt 0 ] && [ "$VOL" -le 33 ]; then
#            printf "🔈 %s%%" "$VOL"
#        elif [ "$VOL" -gt 33 ] && [ "$VOL" -le 66 ]; then
#            printf "🔉 %s%%" "$VOL"
#        else
#            printf "🔊 %s%%" "$VOL"
#        fi
#    else
#        if [[ "$MUTE" = "off" || "$VOL" -eq 0 ]]; then
#            printf "MUTE"
#        elif [ "$VOL" -gt 0 ] && [ "$VOL" -le 33 ]; then
#            printf "VOL %s%%" "$VOL"
#        elif [ "$VOL" -gt 33 ] && [ "$VOL" -le 66 ]; then
#            printf "VOL %s%%" "$VOL"
#        else
#            printf "VOL %s%%" "$VOL"
#        fi
#    fi
#    printf "%s\n" "$SEP2"
}

