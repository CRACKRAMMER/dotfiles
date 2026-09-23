#!/usr/bin/env bash

if [[ $(uname -s) == Darwin ]] && command -v pbcopy >/dev/null 2>&1; then
    exec pbcopy
fi
if [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v wl-copy >/dev/null 2>&1; then
    exec wl-copy
fi
if [[ -n ${DISPLAY:-} ]] && command -v xclip >/dev/null 2>&1; then
    exec xclip -selection clipboard
fi
if [[ -n ${DISPLAY:-} ]] && command -v xsel >/dev/null 2>&1; then
    exec xsel --clipboard --input
fi

cat >/dev/null
