#!/usr/bin/env bash
set -u
(( $# == 0 )) || { printf 'Usage: randomWallpaper.sh\n' >&2; exit 2; }

# Manage only controllers started by these wallpaper scripts, never arbitrary mpv.
script_path=$(readlink -f -- "$0")
[[ "$0" == "$script_path" ]] || exec "$BASH" "$script_path" "$@"
state_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/dotfiles-wallpaper"
mkdir -p -- "$state_dir" || exit 1
chmod 700 -- "$state_dir" || exit 1
pid_file="$state_dir/images.pid"
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
# Keep the original toggle behavior: invoking image mode stops active video mode.
if stop_controller "$state_dir/videos.pid" "$(dirname -- "$script_path")/randomVideoWallpaper.sh"; then exit 0; fi
exec 9>"$state_dir/images.lock"
if ! flock -n 9; then
    stop_controller "$pid_file" "$script_path" || printf 'Wallpaper controller is still starting; try again.\n' >&2
    exit 0
fi
printf '%s\n' "$$" > "$pid_file"
child_pid=''; child_group=0
cleanup() {
    trap - EXIT INT TERM
    if [[ -n "$child_pid" ]]; then
        if (( child_group )); then kill -TERM -- "-$child_pid" 2>/dev/null || true
        else kill -TERM "$child_pid" 2>/dev/null || true; fi
        wait "$child_pid" 2>/dev/null || true
    fi
    rm -f -- "$pid_file"
}
trap cleanup EXIT
trap 'exit 0' INT TERM
run_child() {
    local result
    setsid "$@" 9>&- & child_pid=$!; child_group=1
    wait "$child_pid"; result=$?
    child_pid=''; child_group=0
    return "$result"
}
directory="$HOME/Pictures/Wallpaper/Images"
[[ -d "$directory" ]] || { printf 'Wallpaper image directory does not exist.\n' >&2; exit 1; }
case ${XDG_SESSION_TYPE:-} in
    wayland)
        player=(swww img --transition-type any --transition-step 255)
        if ! swww query >/dev/null 2>&1; then
            command -v swww-daemon >/dev/null || { printf 'swww-daemon is required.\n' >&2; exit 1; }
            swww-daemon 9>&- >/dev/null 2>&1 &
            for (( attempt=0; attempt<50; attempt++ )); do
                swww query >/dev/null 2>&1 && break
                sleep 0.1
            done
            swww query >/dev/null 2>&1 || { printf 'swww-daemon did not become ready.\n' >&2; exit 1; }
        fi
        ;;
    x11) player=(feh --recursive --randomize --bg-fill) ;;
    *) printf 'Wallpaper requires a Wayland or X11 session.\n' >&2; exit 1 ;;
esac
command -v "${player[0]}" >/dev/null || exit 1
while true; do
    mapfile -d '' -t files < <(find -L "$directory" -maxdepth 1 -type f -print0 | shuf -z)
    (( ${#files[@]} )) || { printf 'No wallpaper images found.\n' >&2; exit 1; }
    for file in "${files[@]}"; do
        run_child "${player[@]}" "$file" || exit "$?"
        sleep 10m 9>&- & child_pid=$!; child_group=0
        wait "$child_pid"; result=$?; child_pid=''
        (( result == 0 )) || exit "$result"
    done
done
