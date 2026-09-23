# Dotfiles

[English](README.md)

这是一套用于 Arch Linux 和 macOS 的个人配置，由 [GNU Stow](https://www.gnu.org/software/stow/) 管理。每个顶层目录是一个独立的 Stow 包，只需链接当前机器使用的应用。

## 安装

将仓库克隆到 `~/.dotfiles`，安装 Stow 和需要的应用。终端通用工具可这样安装：

```sh
# Arch Linux
sudo pacman -S --needed git stow zsh neovim tmux ripgrep fzf tree-sitter-cli nodejs npm base-devel zoxide fastfetch aria2 yazi bottom lazygit mpv

# 已安装 Homebrew 的 macOS
./scripts/.local/scripts/install-brew-packages.sh
```

Homebrew 脚本只安装共用的命令行工具；VLC、Zed、Sunshine 等图形应用按需另行安装。Arch 上可使用 pacman 或可信的 AUR 来源。Neovim 当前面向 0.12 及以上版本。安装 Tree-sitter 解析器还需要 C 编译器和 `tree-sitter` CLI。

先预览链接，再正式应用。如果 Stow 报告已有普通文件冲突，请先阅读并备份原文件。

```sh
cd ~/.dotfiles
stow -n -v -t "$HOME" zsh nvim tmux yazi bottom lazygit mpv zed aria2
stow -v -t "$HOME" zsh nvim tmux yazi bottom lazygit mpv zed aria2
```

桌面专用配置按需安装。`sunshine`、`vlc`、`hyprland`、`waybar`、`mangohud`、`systemd` 和 Steam 相关包不在上面的通用命令中。Sunshine 与 VLC 会在配置目录写入运行状态；使用 `--no-folding`，让这些状态文件留在本机目录，而不是仓库中：

```sh
stow -n -v --no-folding -t "$HOME" sunshine vlc
stow -v --no-folding -t "$HOME" sunshine vlc
```

仓库中的 Sunshine 配置针对当前 Arch/KWin 主机。在 macOS 上使用前，应根据机器调整 `capture` 和 `encoder`。已有 Sunshine 安装通常存在 `sunshine.conf` 与 `apps.json` 普通文件，链接前先备份。`sunshine_state.json`、`credentials/` 必须留在本机，不要提交配对状态、私钥、日志、备份或 VLC 最近播放记录。只有确实需要时，才在本机设置 `csrf_allowed_origins`。

部分图形程序在不同平台使用不同目录。Lazygit 可以读取 `$XDG_CONFIG_HOME/lazygit/config.yml`，macOS 的默认回退位置是 `~/Library/Application Support/lazygit/config.yml`。macOS 上 VLC 的首选项路径也不同；链接前先确认应用实际读取的位置。

## 终端与编辑器

- **Zsh：** 交互式 Shell 在 tmux 可用时自动进入 tmux；设置 `DOTFILES_NO_TMUX=1` 可关闭。Oh My Zsh 的 fzf 集成提供 `Ctrl-T`、`Ctrl-R`、`Alt-C`；安装了 fzf-tab 后，按 `Tab` 可用 fzf 选择补全候选。`z`、`zi` 使用 zoxide。仅在标准 AUR 或 Homebrew 路径发现 Anaconda 时初始化 Conda。本机设置放在 Git 忽略的 `zsh/.config/zsh/local.zsh`。
- **tmux：** `Ctrl-h/j/k/l` 在 tmux 面板和 Neovim 分屏之间移动。`Alt-w` 打开 fzf 面板选择器。复制模式下 `v` 选取、`y` 复制到可用的系统剪贴板。状态栏显示 `YYYY-MM-DD HH:MM`。本机设置放在 `tmux/.config/tmux/local.conf`。
- **Neovim：** 首次启动时 `lazy.nvim` 与 Mason 会下载插件和语言服务器。执行 `:DotfilesTSInstall` 安装 Tree-sitter 解析器，升级后可运行 `:TSUpdate`。`lazy-lock.json` 锁定插件版本。界面使用 Tokyo Night Moon；安装 Nerd Font 可正确显示图标。本机设置放在 `nvim/.config/nvim/lua/local.lua`。
- **Yazi：** 已迁移到当前的 `[mgr]` 格式，使用 Git 状态、smart-enter、yamb 书签、compress 四个插件。链接后运行 `ya pkg install` 安装锁定版本。`l`/`Enter` 打开文件或进入目录，`'a` 添加书签，`''` 用 fzf 查找书签，`ca` 打包；音视频交给 mpv。书签状态不会提交到 Git。插件锁定文件面向 Yazi 26.9；升级主版本时同步更新插件。

## 其他应用

| 配置包 | 平台 | 说明 |
| --- | --- | --- |
| `aria2` | Arch、macOS | RPC 仅监听本机；下载到 `~/Downloads`。直接启动前创建 `~/.config/aria2/aria2.session`，Arch 用户服务会自动创建。RPC 密钥只保存在本机。 |
| `bottom` | Arch、macOS | Nord 主题，每秒刷新，显示完整进程命令。 |
| `lazygit` | Arch、macOS | 使用 Neovim 编辑。 |
| `mpv` | Arch、macOS | 记住播放位置，模糊匹配字幕；硬件解码使用 mpv 默认值。 |
| `zed` | Arch、macOS | 跟随系统明暗主题，失焦自动保存，保存时格式化。 |
| `vlc` | 主要用于 Arch | 仅保留少量隐私设置，不收录自动生成的播放记录及界面状态。 |
| `sunshine` | Arch/KWin 配置 | 保留桌面和 Steam Big Picture 项；移除了绑定 `HDMI-1`/`xrandr` 的分辨率切换。 |

其余桌面配置和 DWM 时代的脚本为可选 Linux 包，迁移到新机器前请检查依赖的外部命令。
