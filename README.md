# Dotfiles

[简体中文](README.zh-CN.md)

Personal configuration for Arch Linux and macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a Stow package. Install only the packages for applications you use.

## Install

Clone this repository into `~/.dotfiles`. Install Stow and the applications you want to configure. For the shared terminal setup:

```sh
# Arch Linux
sudo pacman -S --needed git stow zsh neovim tmux ripgrep fzf tree-sitter-cli nodejs npm base-devel zoxide fastfetch aria2 yazi bottom lazygit mpv

# macOS with Homebrew
./scripts/.local/scripts/install-brew-packages.sh
```

The Homebrew script installs the shared command-line tools; install GUI applications such as VLC, Zed, and Sunshine separately if you use them. On Arch, install these from pacman or your trusted AUR source as appropriate. Neovim currently targets version 0.12 or newer. A C compiler and `tree-sitter` CLI are required to install parsers.

Preview links before applying them. Move an existing regular file out of the way if Stow reports a conflict; review its contents before replacing it.

```sh
cd ~/.dotfiles
stow -n -v -t "$HOME" zsh nvim tmux yazi bottom lazygit mpv zed aria2
stow -v -t "$HOME" zsh nvim tmux yazi bottom lazygit mpv zed aria2
```

Install desktop-specific packages separately. `sunshine`, `vlc`, `hyprland`, `waybar`, `mangohud`, `systemd`, and Steam-related packages are not part of the shared command above. Sunshine and VLC write runtime files in their configuration directories, so use `--no-folding` to keep those files outside this checkout:

```sh
stow -n -v --no-folding -t "$HOME" sunshine vlc
stow -v --no-folding -t "$HOME" sunshine vlc
```

The checked-in Sunshine config is for this Arch/KWin host. On macOS, adapt `capture` and `encoder` to the host before using it. A running Sunshine installation already has regular `sunshine.conf` and `apps.json` files; back them up before linking, and keep `sunshine_state.json` and `credentials/` in the host's configuration directory. Never commit pairing state, private keys, logs, backups, or VLC's recent-media UI state. `csrf_allowed_origins` should only be set locally if a particular host needs it.

Some GUI applications use platform-specific configuration locations. Lazygit can use `$XDG_CONFIG_HOME/lazygit/config.yml`; its macOS fallback is `~/Library/Application Support/lazygit/config.yml`. VLC uses a different preferences location on macOS. Check the application's actual config path before linking its Stow package there.

## Terminal and editor

- **Zsh:** The interactive shell starts tmux when available; set `DOTFILES_NO_TMUX=1` to opt out. Oh My Zsh's fzf integration provides `Ctrl-T`, `Ctrl-R`, and `Alt-C`. With fzf-tab, pressing `Tab` opens an fzf completion picker when candidates are available. `z` and `zi` use zoxide when installed. Anaconda initializes only when found at the standard AUR or Homebrew path. Put host-specific settings in `zsh/.config/zsh/local.zsh` (ignored by Git).
- **Kitty:** OS-window closure skips the tmux confirmation only with one tab, one terminal window, and a tmux server with one client and one pane whose Zsh is at a prompt without background jobs or copy mode. Other cases still require confirmation. The `tmux_close.py` watcher uses Zsh prompt hooks; reopen Kitty for the complete setup to take effect. The watcher uses Kitty's internal close handler; if an upgrade makes it incompatible, confirmation remains enabled. Diagnostics are off by default; launch `DOTFILES_KITTY_TMUX_DEBUG=1 kitty` to record close checks in `~/.config/kitty/tmux_close.log` (ignored by Git).
- **tmux:** `Ctrl-h/j/k/l` switches tmux panes. In Neovim normal mode, `Ctrl-h/l` selects the previous/next buffer tab, `Ctrl-j/k` switches vertical splits, and `Space sh/sj/sk/sl` selects the left/down/up/right split. `Alt-w` opens an fzf pane picker. Copy mode `v` selects and `y` copies through an available system clipboard tool. The status bar shows `YYYY-MM-DD HH:MM`. Put host-specific settings in `tmux/.config/tmux/local.conf`. `exit-unattached on` ends the entire server, including background sessions and their programs, when the last client disconnects or manually detaches. Set `set -s exit-unattached off` in that local file if sessions should survive detaching.
- **Neovim:** `lazy.nvim` and Mason fetch plugins and language servers on first use. Run `:DotfilesTSInstall` for Tree-sitter parsers; use `:TSUpdate` after upgrades. `lazy-lock.json` pins plugin versions. The UI uses Tokyo Night Moon; a Nerd Font improves icon rendering. Put local settings in `nvim/.config/nvim/lua/local.lua`.
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
| `sunshine` | Arch/KWin profile | Desktop and Steam Big Picture apps. The fixed `HDMI-1`/`xrandr` mode switch was removed because it is host-specific. |

The remaining desktop and DWM-era scripts are optional Linux packages. Review their external command dependencies before using them on a new machine.

## Verification

Run `python -B tests/test_terminal_close.py` for the Kitty handler and Zsh/tmux prompt tests. Integration tests use isolated temporary sockets and PTYs; they require Linux, tmux and Zsh, and do not operate on existing sessions. Cross-platform handler tests use Python's standard library.
