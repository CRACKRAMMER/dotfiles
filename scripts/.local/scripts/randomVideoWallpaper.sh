#!/usr/bin/env bash
set -u
(( $# == 0 )) || { printf 'Usage: randomVideoWallpaper.sh\n' >&2; exit 2; }

script_path=$(readlink -f -- "$0")
[[ "$0" == "$script_path" ]] || exec "$BASH" "$script_path" "$@"
state_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/dotfiles-wallpaper"
mkdir -p -- "$state_dir" || exit 1
chmod 700 -- "$state_dir" || exit 1
pid_file="$state_dir/videos.pid"
stop_controller() {
    local file=$1 expected=$2 pid command_line
    [[ -r "$file" ]] || return 1
    read -r pid < "$file"
    [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null || return 1
    command_line=$(ps -p "$pid" -o args=) || return 1
    case "$command_line" in
        "bash $expected"|"/bin/bash $expected"|"/usr/bin/bash $expected") kill -TERM "$pid" ;;
        *) return 1 ;;
    esac
}
exec 9>"$state_dir/videos.lock"
if ! flock -n 9; then
    stop_controller "$pid_file" "$script_path" || printf 'Wallpaper controller is still starting; try again.\n' >&2
    exit 0
fi
stop_controller "$state_dir/images.pid" "$(dirname -- "$script_path")/randomWallpaper.sh" || true
printf '%s\n' "$$" > "$pid_file"
child_pid=''
cleanup() {
    trap - EXIT INT TERM
    if [[ -n "$child_pid" ]]; then
        kill -TERM -- "-$child_pid" 2>/dev/null || true
        wait "$child_pid" 2>/dev/null || true
    fi
    rm -f -- "$pid_file"
}
trap cleanup EXIT
trap 'exit 0' INT TERM
run_child() {
    local result
    setsid "$@" 9>&- & child_pid=$!
    wait "$child_pid"; result=$?; child_pid=''
    return "$result"
}
directory="$HOME/Pictures/Wallpaper/Videos"
[[ -d "$directory" ]] || { printf 'Wallpaper video directory does not exist.\n' >&2; exit 1; }
case ${XDG_SESSION_TYPE:-} in
    wayland) player=(mpvpaper -vs -o 'no-audio loop' '*') ;;
    x11) player=(xwinwrap -fs -nf -ni -ov -- mpv -wid WID --loop --no-audio) ;;
    *) printf 'Video wallpaper requires a Wayland or X11 session.\n' >&2; exit 1 ;;
esac
command -v "${player[0]}" >/dev/null || exit 1
while true; do
    mapfile -d '' -t files < <(find -L "$directory" -maxdepth 1 -type f \
        \( -iname '*.mp4' -o -iname '*.avi' -o -iname '*.wmv' -o -iname '*.mkv' -o -iname '*.webm' \) -print0 | shuf -z)
    (( ${#files[@]} )) || { printf 'No wallpaper videos found.\n' >&2; exit 1; }
    for file in "${files[@]}"; do run_child "${player[@]}" "$file" || exit "$?"; done
done
