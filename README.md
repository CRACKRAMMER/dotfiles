# Dotfiles

[简体中文](README.zh-CN.md)

Personal configuration for Arch Linux and macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a Stow package. Install only the packages for applications you use.

## Sync across computers

Use `master` on every computer for the shared configuration and pinned plugins. The `hr` history has been merged into `master`, with the GitHub version taking precedence for overlapping configuration. Make future shared changes on `master` rather than keeping separate branches for each computer.

On a new computer, clone the repository, then link the packages you use as described below:

```sh
git clone --branch master https://github.com/CRACKRAMMER/dotfiles.git ~/.dotfiles
```

On an existing computer, back up uncommitted changes and untracked files before updating:

```sh
cd ~/.dotfiles
git fetch origin
git switch master
git pull --ff-only origin master
```

After updating, repeat the Stow preview and link commands for your packages, run `ya pkg install`, and run `:Lazy restore` in Neovim to use the pinned plugin versions. Open a new terminal for Zsh changes and reopen Kitty for its watcher. Keep disk UUIDs, service enablement and credentials in local files while sharing the configuration itself.

`clean-copy.nvim` is private, so each computer needs GitHub authentication with access to it. If GitHub SSH access is already configured, route that plugin's HTTPS URL through SSH:

```sh
git config --global url."git@github.com:CRACKRAMMER/clean-copy.nvim.git".insteadOf https://github.com/CRACKRAMMER/clean-copy.nvim.git
```

## Install

Clone this repository into `~/.dotfiles`. Install Stow and the applications you want to configure. For the shared terminal setup:

```sh
# Arch Linux
sudo pacman -S --needed git stow zsh neovim tmux ripgrep fzf tree-sitter-cli ctags nodejs npm base-devel zoxide fastfetch aria2 yazi bottom lazygit mpv

# macOS with Homebrew
./scripts/.local/scripts/install-brew-packages.sh
```

The Homebrew script installs the shared command-line tools; install GUI applications such as VLC, Zed, and Sunshine separately if you use them. On Arch, install these from pacman or your trusted AUR source as appropriate. Neovim currently targets version 0.12 or newer. A C compiler and `tree-sitter` CLI are required to install parsers.

Preview links before applying them. Move an existing regular file out of the way if Stow reports a conflict; review its contents before replacing it.

```sh
cd ~/.dotfiles
stow -n -v -t "$HOME" zsh nvim tmux yazi bottom lazygit zed aria2
stow -v -t "$HOME" zsh nvim tmux yazi bottom lazygit zed aria2
```

Install desktop-specific packages separately. `sunshine`, `vlc`, `hyprland`, `waybar`, `mangohud`, `systemd`, and Steam-related packages are not part of the shared command above. Sunshine, VLC and macOS mpv write runtime files in their configuration directories, so use `--no-folding` to keep those files outside this checkout:

```sh
stow -n -v --no-folding -t "$HOME" sunshine vlc mpv
stow -v --no-folding -t "$HOME" sunshine vlc mpv
```

The checked-in Sunshine config targets Linux + Plasma on Wayland using KWin capture and VAAPI encoding. Only `sunshine.conf` is shared. Each computer maintains its own application list in `apps.json`, which Git ignores. Back up an existing regular `sunshine.conf` before linking; keep `apps.json`, `sunshine_state.json` and `credentials/` in the host's configuration directory. Never commit pairing state, private keys, logs, backups, or VLC's recent-media UI state. `csrf_allowed_origins` should only be set locally if a particular host needs it.

Some GUI applications use platform-specific configuration locations. Lazygit can use `$XDG_CONFIG_HOME/lazygit/config.yml`; its macOS fallback is `~/Library/Application Support/lazygit/config.yml`. VLC uses a different preferences location on macOS. Check the application's actual config path before linking its Stow package there.

## Terminal and editor

- **Zsh:** The interactive shell starts tmux when available; set `DOTFILES_NO_TMUX=1` to opt out. Oh My Zsh's fzf integration provides `Ctrl-T`, `Ctrl-R`, and `Alt-C`. With fzf-tab, pressing `Tab` opens an fzf completion picker when candidates are available. `z` and `zi` use zoxide when installed. Anaconda initializes only when found at the standard AUR or Homebrew path. Put host-specific settings in `zsh/.config/zsh/local.zsh` (ignored by Git).
- **Zsh environment:** `.zshenv` uses Neovim as the editor, the XDG directories and `$XDG_DATA_HOME/go` for GOPATH; its `bin` directory and an explicitly set GOBIN are added to PATH. Linux uses `google-chrome-stable`, enables Proton Wayland, sets `$HOME/Wine`, and selects the Podman Docker socket when `XDG_RUNTIME_DIR` is set. Ollama models use `$HOME/Disk/OllamaModels`; Hugging Face uses `$HOME/Data/Cache/huggingface`. Linux sets `CURL_CA_BUNDLE` when `/etc/ssl/certs/ca-certificates.crt` is readable. On macOS the browser defaults to `open`. On Linux, run `systemctl --user enable --now podman.socket` before using Podman through the Docker API or Compose.
- **Boot Windows once:** On Linux, `boot-win` verifies that Boot0002 is an active Windows Boot Manager entry, sets UEFI BootNext with `sudo efibootmgr --bootnext 0002`, then calls `sudo systemctl reboot` only if that write succeeds. Loading the shell does not change firmware settings. BootNext applies once and leaves BootOrder unchanged. Put `DOTFILES_WINDOWS_BOOT_ENTRY=XXXX` in `zsh/.config/zsh/local.zsh` to select another Windows entry; confirm its number with `efibootmgr` first. Inspect a pending choice with `efibootmgr`; cancel it with `sudo efibootmgr --delete-bootnext`. See the [efibootmgr documentation](https://github.com/rhboot/efibootmgr#readme).
- **Kitty:** On Linux, OS-window closure skips the tmux confirmation only with one tab, one terminal window, and a tmux server with one client and one pane whose Zsh is at a prompt without background jobs (including jobs detached with `disown` or `&!`) or copy mode. Known Powerlevel10k and Oh My Zsh prompt workers are allowed. Other cases, unreadable process state and other operating systems retain confirmation. The `tmux_close.py` watcher uses Zsh prompt hooks; reopen Kitty for the complete setup to take effect. The watcher uses Kitty's internal close handler; if an upgrade makes it incompatible, confirmation remains enabled. Diagnostics are off by default; launch `DOTFILES_KITTY_TMUX_DEBUG=1 kitty` to record close checks in `~/.config/kitty/tmux_close.log` (ignored by Git).
- **tmux:** `Ctrl-h/j/k/l` switches tmux panes. In Neovim normal mode, `Ctrl-h/l` selects the previous/next buffer tab, `Ctrl-j/k` switches vertical splits, and `Space sh/sj/sk/sl` selects the left/down/up/right split. `Alt-w` opens an fzf pane picker. Copy mode `v` selects and `y` copies through an available system clipboard tool. The status bar shows `YYYY-MM-DD HH:MM`. Put host-specific settings in `tmux/.config/tmux/local.conf`. `exit-unattached on` ends the entire server, including background sessions and their programs, when the last client disconnects or manually detaches. Set `set -s exit-unattached off` in that local file if sessions should survive detaching.
- **Neovim:** `lazy.nvim` and Mason fetch plugins and language servers on first use. Run `:DotfilesTSInstall` for Tree-sitter parsers; use `:TSUpdate` after upgrades. `lazy-lock.json` pins plugin versions. The UI uses Tokyo Night Moon; a Nerd Font improves icon rendering. Put local settings in `nvim/.config/nvim/lua/local.lua`. Taglist on `Space l` requires Universal Ctags (`ctags` on Arch, `universal-ctags` in Homebrew); missing dependencies produce a message. clangd takes the C/C++ standard from project `compile_commands.json` or `.clangd`, with no globally forced C++20.
- **Copy without comments:** [clean-copy.nvim](https://github.com/CRACKRAMMER/clean-copy.nvim) is maintained separately and pinned in `lazy-lock.json`. Select code in Visual mode and press `Space cy`; use `:CleanCopy` for the whole buffer or `:[range]CleanCopy` for a line range. Normal `y` and the source buffer remain unchanged. Run `:DotfilesTSInstall` to install the configured parsers, including SQL, C/C++, JS/TS/JSX/TSX, Rust, Go, Python, PHP, C#, HTML, CSS, Java, Vue and Lua. Mixed-language files also need their embedded parsers. Missing parsers produce a warning rather than installing on copy. Clipboard output requires a provider such as `wl-copy`, `xclip`, `xsel`, or macOS `pbcopy`; local registers remain available. Python docstrings and recognized tool directives are preserved by default. SQL dialect and embedded-language limits are documented in the plugin repository.
- **Yazi:** This configuration uses the current `[mgr]` schema and four plugins: Git status, smart-enter, yamb bookmarks, and compress. Install/update the pinned plugins with `ya pkg install` after linking. `l`/`Enter` opens a file or enters a directory; `'a` adds a bookmark, `''` searches bookmarks with fzf, and `ca` creates an archive. mpv opens audio and video. Bookmark state is ignored by Git. The plugin lock file targets Yazi 26.9; update Yazi and plugins together when changing major versions.

## Other applications

| Package | Scope | Notes |
| --- | --- | --- |
| `aria2` | Arch, macOS | RPC binds to localhost. Downloads go to `~/Downloads`; create `~/.config/aria2/aria2.session` for direct starts. The Arch user service creates it automatically. Keep RPC secrets local. |
| `bottom` | Arch, macOS | Nord theme, one-second refresh, full process commands. |
| `lazygit` | Arch, macOS | Uses Neovim as its editor. |
| `mpv` | Arch, macOS | Saves playback position; fuzzy subtitle matching. Hardware decoding stays at mpv's default. |
| `zed` | Arch, macOS | System light/dark theme, autosave on focus change, format on save. |
| `vlc` | Primarily Arch | Minimal privacy settings; no generated playback history or UI state. |
| `sunshine` | Linux + Plasma (Wayland) | Shares only `sunshine.conf` using KWin capture and VAAPI encoding. App lists, pairing data and user service overrides remain local. |

The remaining desktop and DWM-era scripts are optional Linux packages. Review their external command dependencies before using them on a new machine. `steam-switch.sh` validates account files and refuses to replace regular files or directories; a failed link update rolls back the changed links. The wallpaper scripts preserve filenames literally and manage only their own controllers and players. They use Linux util-linux (`flock`, `setsid`), the selected graphical backend, and a private state directory at `$XDG_RUNTIME_DIR/dotfiles-wallpaper` (or the XDG cache directory when no runtime directory is set).

## Optional Linux user services

The `systemd` package provides aria2, macast, Ollama and an optional disk mount service. Each computer generates its own enablement links (`*.wants/`) with `systemctl --user enable`. These links are ignored by Git, so cloning the repository does not enable services.

```sh
stow -n -v -t "$HOME" systemd
stow -v -t "$HOME" systemd
systemctl --user daemon-reload
# Enable only installed services this computer needs, for example:
systemctl --user enable --now ollama.service
```

Ollama defaults to `~/Disk/OllamaModels`. To use another model directory, copy `~/.config/dotfiles/ollama.env.example` to `ollama.env` beside it and set `OLLAMA_MODELS` to the actual absolute path. These `.env` files are ignored by Git. systemd EnvironmentFile values do not expand `$HOME` or `~`; see the [systemd environment documentation](https://github.com/systemd/systemd/blob/main/man/systemd.exec.xml).

`udisksd.service` is a user service that mounts a local disk through UDisks, separate from the system UDisks daemon. When needed, copy `mount.env.example` to `mount.env`, set `DOTFILES_MOUNT_DEVICE` using the UUID from `lsblk -f`, then run `systemctl --user enable --now udisksd.service`. Mounting is skipped without `mount.env`; when both services are enabled, the mount runs before Ollama. The optional `udevadm-monitor.sh` can be run manually to mount newly added block devices containing filesystems. It needs `udevadm`, `stdbuf`, `awk` and `udisksctl`.

## Verification

Run the regression checks from the repository root:

```sh
python -B -m unittest discover -s tests -p 'test_*.py'
nvim --headless -u NONE -i NONE -l tests/test_nvim_taglist.lua
```

Kitty/tmux integration uses isolated temporary sockets and PTYs; it requires Linux, tmux and Zsh. The full prompt test also needs the Arch Oh My Zsh/Powerlevel10k packages. Desktop script tests use temporary homes and mocked processes without operating on existing sessions or Steam files. clangd checks require clangd; Taglist checks require the installed plugin and Universal Ctags. Unavailable integration dependencies are reported as skipped.
