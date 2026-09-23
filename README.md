# Dotfiles

Configuration for Arch Linux and macOS. The shared packages are `nvim`, `tmux`, and `zsh`; desktop packages such as `hyprland` and `waybar` are Linux-specific.

## Shared setup

Install the tools used by the shared configuration. This setup was tested with Neovim 0.12; use 0.12 or newer. The Tree-sitter parser installer also needs a C compiler and the `tree-sitter` CLI. On macOS, install the Xcode Command Line Tools for the compiler.

```sh
# Arch Linux
sudo pacman -S --needed git stow zsh neovim tmux ripgrep fzf tree-sitter-cli nodejs npm base-devel zoxide fastfetch zsh-autosuggestions zsh-syntax-highlighting

# macOS, with Homebrew already installed and in PATH
./scripts/.local/scripts/install-brew-packages.sh
```

From the repository directory, preview the links before creating them:

```sh
stow -n -v -t "$HOME" nvim tmux
stow -v -t "$HOME" nvim tmux
```

The `zsh` package is optional: preview it separately with `stow -n -v -t "$HOME" zsh` because many machines already have a `.zshrc`. Review and move any existing files that Stow reports as conflicts. The Zsh configuration respects existing `BROWSER`, `EDITOR`, XDG, and Go path settings. Put machine-specific interactive settings in `zsh/.config/zsh/local.zsh`; it is loaded by `.zshrc` and ignored by Git. Link Linux desktop packages separately on Arch, according to the applications installed on that machine.
If Anaconda is installed by the AUR package at `/opt/anaconda` or Homebrew's cask at its default `anaconda3` path, interactive Zsh initializes Conda automatically. It skips this step when Conda is already initialized.

## Neovim

On first start, `lazy.nvim` installs plugins and Mason installs the configured language servers. Both steps need network access. Run `:DotfilesTSInstall` once to install the configured Tree-sitter parsers; reopen any already open buffer to enable highlighting. After plugin updates, run `:TSUpdate`.

`lazy-lock.json` is tracked for matching plugin revisions across machines. Lazy may replace it during the first installation. On a fresh machine, restore that file from Git after the first install, then run `:Lazy restore`. Update the lockfile intentionally with `:Lazy update`.

Telescope's text search needs `rg`. Markdown preview uses `npm` to install its local dependencies. The Fcitx plugin loads only when `fcitx-remote` or `fcitx5-remote` is available. System clipboard integration uses `pbcopy` on macOS and a Wayland or X11 clipboard tool on Linux.

For settings specific to one machine, create `nvim/.config/nvim/lua/local.lua` in this checkout. It is loaded last and ignored by Git.

The UI uses Tokyo Night Moon with a solid editor background, a rounded float border, a shared status line, and slanted buffer tabs. Kitty, Foot, and WezTerm use matching colors. Their font sizes remain independent; install FiraCode Nerd Font on any machine where you want the icons and separators to render correctly.

## tmux

`Ctrl-h/j/k/l` moves between tmux panes and Neovim splits. `Alt-w` opens the fzf pane picker. In copy mode, `v` starts selection and `y` copies to the system clipboard using `pbcopy`, `wl-copy`, `xclip`, or `xsel`, whichever is available.

The default status line uses tmux built-ins. The bundled `tmux-powerline` scripts remain available for manual use, but their network and platform-specific segments are not run by default. Put machine-specific tmux settings in `tmux/.config/tmux/local.conf`; it is sourced last and ignored by Git.

Interactive Zsh starts tmux when available. Set `DOTFILES_NO_TMUX=1` before starting Zsh to disable that behavior on a particular machine or terminal. Zsh enables the Oh My Zsh `fzf` plugin when installed, or loads fzf's own shell integration if Oh My Zsh is unavailable. This adds `Ctrl-T`, `Ctrl-R`, and `Alt-C`. Pressing `Tab` opens fzf-tab's completion picker when there are multiple candidates; no `**` prefix is needed. `fetch` runs Fastfetch, and `z`/`zi` use zoxide when installed (falling back to autojump if zoxide is absent). The vendored fzf-tab source is from [Aloxaf/fzf-tab](https://github.com/Aloxaf/fzf-tab) commit `24105b15714bfec37989ed5c5b6e60f572253019` (MIT license). The tmux status line shows `YYYY-MM-DD HH:MM`.

## Other configurations

The VS Code OSS settings use `nvim` from `PATH`, so install Neovim first. If a macOS GUI launch does not inherit the Homebrew path, set `vim.neovimPath` in that machine's VS Code user settings to the output of `command -v nvim`. On macOS, VS Code uses a different settings directory; copy or link this file there if you use VS Code OSS. The aria2 configuration stores downloads in `~/Downloads`, does not force a proxy, and binds RPC to localhost. Create `~/Downloads` and `~/.config/aria2/aria2.session` before starting aria2 directly; the Arch systemd user service creates the session file for you. Use a machine-local aria2 configuration if you need remote RPC access or a proxy.

The `systemd`, `hyprland`, `mangohud`, and Steam packages are Arch/Linux-specific and should not be Stowed on macOS.
The Linux volume shortcuts use `pactl` or `wpctl`; the optional volume menu also needs `wofi`, `rofi`, or `fuzzel`.
