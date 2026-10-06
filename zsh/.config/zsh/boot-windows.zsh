# BootNext selects Windows once without changing the normal UEFI BootOrder.
[[ $OSTYPE == linux* ]] || return 0

unalias boot-win 2>/dev/null
boot-win() {
    local boot_entry=${DOTFILES_WINDOWS_BOOT_ENTRY:-0002}
    local boot_listing line found=0

    if [[ ! $boot_entry =~ '^[[:xdigit:]]{4}$' ]]; then
        print -u2 -- 'boot-win: DOTFILES_WINDOWS_BOOT_ENTRY must contain four hex digits'
        return 1
    fi
    boot_entry=${(U)boot_entry}
    if ! command -v efibootmgr >/dev/null 2>&1 || ! command -v systemctl >/dev/null 2>&1; then
        print -u2 -- 'boot-win: efibootmgr and systemctl are required'
        return 1
    fi
    boot_listing=$(command efibootmgr) || return 1
    for line in ${(f)boot_listing}; do
        if [[ $line =~ "^Boot${boot_entry}\\*[[:space:]]+Windows Boot Manager([[:space:]]|$)" ]]; then
            found=1
            break
        fi
    done
    if (( ! found )); then
        print -u2 -- "boot-win: active Windows Boot Manager entry Boot${boot_entry} not found"
        return 1
    fi

    sudo efibootmgr --bootnext "$boot_entry" && sudo systemctl reboot
}
