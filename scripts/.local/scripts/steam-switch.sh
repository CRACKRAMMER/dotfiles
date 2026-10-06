#!/usr/bin/env bash
set -euo pipefail

fail() { printf 'Steam switch: %s\n' "$*" >&2; exit 1; }
games_path="$HOME/Games/SteamUser"
(( $# <= 1 )) || fail 'usage: steam-switch.sh [account]'

if (( $# )); then
    steam_user=$1
else
    [[ -d "$games_path" ]] || fail 'account directory does not exist'
    case ${XDG_SESSION_TYPE:-} in
        wayland) picker=(wofi -W 500 -H 500 -d -n -i --prompt steam-switch) ;;
        x11) picker=(rofi -dmenu -p steam-switch) ;;
        *) fail 'a Wayland or X11 session is needed for the account menu' ;;
    esac
    command -v "${picker[0]}" >/dev/null || fail "missing ${picker[0]}"
    accounts=()
    shopt -s nullglob
    for account in "$games_path"/*/; do
        name=${account%/}; name=${name##*/}
        [[ "$name" != *$'\n'* && "$name" != *$'\r'* ]] && accounts+=("$name")
    done
    (( ${#accounts[@]} )) || fail 'no accounts found'
    steam_user=$(printf '%s\n' "${accounts[@]}" | "${picker[@]}") || exit 0
fi

# A cancelled menu and any path component must be rejected before touching links.
[[ -n "$steam_user" ]] || exit 0
[[ "$steam_user" != . && "$steam_user" != .. && "$steam_user" != */* &&
   "$steam_user" != *$'\n'* && "$steam_user" != *$'\r'* ]] || fail 'invalid account name'
source_dir="$games_path/$steam_user"
[[ -d "$source_dir" ]] || fail 'selected account does not exist'

sources=(
    "$source_dir/Steam/ubuntu12_32" "$source_dir/Steam/ubuntu12_64"
    "$source_dir/Steam" "$source_dir/Steam"
    "$source_dir/Steam/linux32" "$source_dir/Steam/linux64"
    "$source_dir/Steam" "$source_dir/registry.vdf" "$source_dir/steam.token"
)
destinations=(
    "$HOME/.steam/bin32" "$HOME/.steam/bin64" "$HOME/.steam/root" "$HOME/.steam/steam"
    "$HOME/.steam/sdk32" "$HOME/.steam/sdk64" "$HOME/.local/share/Steam"
    "$HOME/.steam/registry.vdf" "$HOME/.steam/steam.token"
)
old_targets=(); had_link=()
for i in "${!sources[@]}"; do
    if (( i < 7 )); then
        [[ -d "${sources[i]}" ]] || fail 'selected account is missing a Steam directory'
    else
        [[ -f "${sources[i]}" ]] || fail 'selected account is missing registry.vdf or steam.token'
    fi
    destination=${destinations[i]}
    if [[ -L "$destination" ]]; then
        had_link[i]=1
        old_targets[i]=$(readlink -- "$destination") || fail 'cannot read an existing link'
    elif [[ -e "$destination" ]]; then
        fail "refusing to replace a regular file or directory: $destination"
    else
        had_link[i]=0; old_targets[i]=''
    fi
done

command -v pgrep >/dev/null || fail 'pgrep is required to check whether Steam is running'
if pgrep -u "$UID" -x 'steam(\.sh)?|steamwebhelper' >/dev/null; then
    fail 'exit Steam before switching accounts'
else
    status=$?
    (( status == 1 )) || fail 'cannot check Steam processes'
fi

# Prepare links and backups on the destination filesystems before the first change.
mkdir -p -- "$HOME/.steam" "$HOME/.local/share"
exec 9>"$HOME/.steam/.dotfiles-switch.lock"
flock -n 9 || fail 'another account switch is in progress'
stages=(); committed=(); finished=0; preserve_stages=0
rollback() {
    local i n destination ok=0
    for (( n=${#committed[@]}-1; n>=0; n-- )); do
        i=${committed[n]}; destination=${destinations[i]}
        if (( had_link[i] )); then
            if [[ -L "$destination" ]] && [[ $(readlink -- "$destination") == "${old_targets[i]}" ]]; then continue; fi
        elif [[ ! -e "$destination" && ! -L "$destination" ]]; then
            continue
        fi
        # Never remove a regular object or an unrelated link created concurrently.
        if [[ ! -L "$destination" ]] || [[ $(readlink -- "$destination") != "${sources[i]}" ]]; then
            printf 'Steam switch: cannot restore changed destination %s; backups retained.\n' "$destination" >&2
            ok=1; continue
        fi
        if (( had_link[i] )); then
            mv -Tf -- "${backup_paths[i]}" "$destination" || ok=1
        else
            rm -- "$destination" || ok=1
        fi
    done
    (( ok == 0 )) || preserve_stages=1
    return "$ok"
}
cleanup() {
    local status=$?
    trap - EXIT INT TERM
    if (( ! finished )); then rollback || status=1; fi
    if (( ! preserve_stages )); then
        for stage in "${stages[@]}"; do rm -rf -- "$stage"; done
    else
        printf 'Steam switch: recovery directories: %s\n' "${stages[*]}" >&2
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
steam_stage=$(mktemp -d "$HOME/.steam/.dotfiles-switch.XXXXXX")
stages+=("$steam_stage")
share_stage=$(mktemp -d "$HOME/.local/share/.dotfiles-switch.XXXXXX")
stages+=("$share_stage")
new_paths=(); backup_paths=()
for i in "${!sources[@]}"; do
    stage=$steam_stage
    (( i != 6 )) || stage=$share_stage
    new_paths[i]="$stage/new-$i"; backup_paths[i]="$stage/old-$i"
    ln -s -- "${sources[i]}" "${new_paths[i]}"
    if (( had_link[i] )); then ln -s -- "${old_targets[i]}" "${backup_paths[i]}"; fi
done
for i in "${!sources[@]}"; do
    destination=${destinations[i]}
    if (( had_link[i] )); then
        [[ -L "$destination" ]] && [[ $(readlink -- "$destination") == "${old_targets[i]}" ]] ||
            fail 'an existing destination changed during preparation'
    else
        [[ ! -e "$destination" && ! -L "$destination" ]] || fail 'a destination appeared during preparation'
    fi
    committed+=("$i")
    mv -Tf -- "${new_paths[i]}" "$destination"
done
finished=1
printf 'Steam account switched to %s.\n' "$steam_user"
