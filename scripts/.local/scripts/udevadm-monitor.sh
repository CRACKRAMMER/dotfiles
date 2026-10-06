#!/bin/sh

# Mount filesystem devices added after this optional monitor starts.
stdbuf -oL udevadm monitor --udev --subsystem-match=block |
while read -r _ _ event devpath _; do
    case "$event:$devpath" in
        add:/devices/*) ;;
        *) continue ;;
    esac

    properties=$(udevadm info --query=property --path="/sys$devpath") || continue
    usage=$(printf '%s\n' "$properties" | awk -F= '$1 == "ID_FS_USAGE" { print $2 }')
    [ "$usage" = filesystem ] || continue
    devname=$(printf '%s\n' "$properties" | awk -F= '$1 == "DEVNAME" { print substr($0, index($0, "=") + 1) }')
    [ -n "$devname" ] || continue
    udisksctl mount --block-device "$devname" --no-user-interaction
done
