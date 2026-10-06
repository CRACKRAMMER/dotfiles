# Dotfiles

[English](README.md)

这是一套用于 Arch Linux 和 macOS 的个人配置，由 [GNU Stow](https://www.gnu.org/software/stow/) 管理。每个顶层目录是一个独立的 Stow 包，只需链接当前机器使用的应用。

## 多台电脑同步

所有电脑统一使用 `master`，共用配置和插件锁定版本。`hr` 的历史已合并到 `master`，同名配置采用 GitHub 上的版本；后续修改共用配置也提交到 `master`，不再按电脑维护不同分支。

新电脑先克隆，再按下面的安装步骤链接需要的包：

```sh
git clone --branch master https://github.com/CRACKRAMMER/dotfiles.git ~/.dotfiles
```

已有电脑先备份未提交修改和未跟踪文件，再更新：

```sh
cd ~/.dotfiles
git fetch origin
git switch master
git pull --ff-only origin master
```

更新后重新执行所用包的 Stow 预览和链接命令，运行 `ya pkg install`，并在 Neovim 中执行 `:Lazy restore`，让插件使用仓库锁定的版本。新开终端加载 Zsh 配置；Kitty 的 watcher 需要重开 Kitty。磁盘 UUID、服务启用状态和私密信息保留在本机文件中，共用配置保持一致。

`clean-copy.nvim` 是私有仓库，每台电脑需要可访问它的 GitHub 认证。如果已经配置好 GitHub SSH 访问，可让该插件的 HTTPS 地址使用 SSH：

```sh
git config --global url."git@github.com:CRACKRAMMER/clean-copy.nvim.git".insteadOf https://github.com/CRACKRAMMER/clean-copy.nvim.git
```

## 安装

将仓库克隆到 `~/.dotfiles`，安装 Stow 和需要的应用。终端通用工具可这样安装：

```sh
# Arch Linux
sudo pacman -S --needed git stow zsh neovim tmux ripgrep fzf tree-sitter-cli ctags nodejs npm base-devel zoxide fastfetch aria2 yazi bottom lazygit mpv

# 已安装 Homebrew 的 macOS
./scripts/.local/scripts/install-brew-packages.sh
```

Homebrew 脚本只安装共用的命令行工具；VLC、Zed、Sunshine 等图形应用按需另行安装。Arch 上可使用 pacman 或可信的 AUR 来源。Neovim 当前面向 0.12 及以上版本。安装 Tree-sitter 解析器还需要 C 编译器和 `tree-sitter` CLI。

先预览链接，再正式应用。如果 Stow 报告已有普通文件冲突，请先阅读并备份原文件。

```sh
cd ~/.dotfiles
stow -n -v -t "$HOME" zsh nvim tmux yazi bottom lazygit zed aria2
stow -v -t "$HOME" zsh nvim tmux yazi bottom lazygit zed aria2
```

桌面专用配置按需安装。`sunshine`、`vlc`、`hyprland`、`waybar`、`mangohud`、`systemd` 和 Steam 相关包不在上面的通用命令中。Sunshine、VLC 和 macOS 上的 mpv 会在配置目录写入运行状态；使用 `--no-folding`，让这些状态文件留在本机目录，而不是仓库中：

```sh
stow -n -v --no-folding -t "$HOME" sunshine vlc mpv
stow -v --no-folding -t "$HOME" sunshine vlc mpv
```

仓库中的 Sunshine 配置针对 Linux + Plasma（Wayland），使用 KWin 捕获和 VAAPI 编码，只同步 `sunshine.conf`。`apps.json` 是每台电脑自己的应用列表，由 Sunshine 在本机维护并由 Git 忽略。已有 Sunshine 安装通常存在 `sunshine.conf` 普通文件，链接前先备份。`sunshine_state.json`、`credentials/` 也必须留在本机，不要提交配对状态、私钥、日志、备份或 VLC 最近播放记录。只有确实需要时，才在本机设置 `csrf_allowed_origins`。

部分图形程序在不同平台使用不同目录。Lazygit 可以读取 `$XDG_CONFIG_HOME/lazygit/config.yml`，macOS 的默认回退位置是 `~/Library/Application Support/lazygit/config.yml`。macOS 上 VLC 的首选项路径也不同；链接前先确认应用实际读取的位置。

## 终端与编辑器

- **Zsh：** 交互式 Shell 在 tmux 可用时自动进入 tmux；设置 `DOTFILES_NO_TMUX=1` 可关闭。Oh My Zsh 的 fzf 集成提供 `Ctrl-T`、`Ctrl-R`、`Alt-C`；安装了 fzf-tab 后，按 `Tab` 可用 fzf 选择补全候选。`z`、`zi` 使用 zoxide。仅在标准 AUR 或 Homebrew 路径发现 Anaconda 时初始化 Conda。本机设置放在 Git 忽略的 `zsh/.config/zsh/local.zsh`。
- **Zsh 环境变量：** `.zshenv` 使用 Neovim 作为编辑器，沿用 XDG 目录，GOPATH 改为 `$XDG_DATA_HOME/go`，其 `bin` 和显式设置的 GOBIN 会加入 PATH。Linux 使用 `google-chrome-stable`，启用 Proton Wayland，设置 `$HOME/Wine`，并在 `XDG_RUNTIME_DIR` 有值时使用 Podman 的 Docker socket。Ollama 模型目录为 `$HOME/Disk/OllamaModels`，Hugging Face 缓存为 `$HOME/Data/Cache/huggingface`；Linux 的 `/etc/ssl/certs/ca-certificates.crt` 可读时设置 `CURL_CA_BUNDLE`。macOS 浏览器默认使用 `open`。Linux 首次使用 Podman 的 Docker API/Compose 前执行 `systemctl --user enable --now podman.socket`，启用用户 socket。
- **单次启动 Windows：** Linux 下执行 `boot-win` 会验证 Boot0002 是已启用的 Windows Boot Manager，执行 `sudo efibootmgr --bootnext 0002` 设置 UEFI BootNext，成功后才执行 `sudo systemctl reboot`。加载 Shell 不会修改固件设置。BootNext 仅用于下一次启动，不改变 BootOrder。其他机器先用 `efibootmgr` 确认编号，再在 `zsh/.config/zsh/local.zsh` 中设置 `DOTFILES_WINDOWS_BOOT_ENTRY=XXXX`。用 `efibootmgr` 查看待启动项；用 `sudo efibootmgr --delete-bootnext` 取消。参见 [efibootmgr 文档](https://github.com/rhboot/efibootmgr#readme)。
- **Kitty：** Linux 下关闭 OS 窗口时，仅在一个标签、一个终端窗口、tmux 服务器只有一个客户端和一个面板，且 Zsh 停在提示符、没有后台任务（包括 `disown` 或 `&!` 脱离作业表的任务）、未进入复制模式时，跳过 tmux 的关闭确认。允许已识别的 Powerlevel10k 和 Oh My Zsh 提示符辅助进程。其他情况、无法读取进程状态或其他操作系统仍保留确认。`tmux_close.py` watcher 配合 Zsh 提示符钩子实现；新配置需要重开 Kitty 才能完整生效。watcher 使用 Kitty 内部关闭处理接口，升级 Kitty 后若接口不兼容，会保留确认行为。诊断日志默认关闭；使用 `DOTFILES_KITTY_TMUX_DEBUG=1 kitty` 启动时，关闭检查写入 `~/.config/kitty/tmux_close.log`，该文件已被 Git 忽略。
- **tmux：** `Ctrl-h/j/k/l` 切换 tmux 面板；在 Neovim 中，普通模式下 `Ctrl-h/l` 保留为上一个/下一个文件标签，`Ctrl-j/k` 切换上下分屏，`空格 sh/sj/sk/sl` 分别切换到左/下/上/右分屏。`Alt-w` 打开 fzf 面板选择器。复制模式下 `v` 选取、`y` 复制到可用的系统剪贴板。状态栏显示 `YYYY-MM-DD HH:MM`。本机设置放在 `tmux/.config/tmux/local.conf`。`exit-unattached on` 会在最后一个客户端断开或手动 detach 时结束整个服务器，包括后台会话和其中的程序；需要保留这些会话时，在该本机文件中设置 `set -s exit-unattached off`。
- **Neovim：** 首次启动时 `lazy.nvim` 与 Mason 会下载插件和语言服务器。执行 `:DotfilesTSInstall` 安装 Tree-sitter 解析器，升级后可运行 `:TSUpdate`。`lazy-lock.json` 锁定插件版本。界面使用 Tokyo Night Moon；安装 Nerd Font 可正确显示图标。本机设置放在 `nvim/.config/nvim/lua/local.lua`。Taglist 的 `空格 l` 需要 Universal Ctags（Arch：`ctags`，Homebrew：`universal-ctags`），缺失时会提示。clangd 的 C/C++ 标准由项目 `compile_commands.json` 或 `.clangd` 管理，不再全局强制 C++20。
- **去注释复制：** [clean-copy.nvim](https://github.com/CRACKRAMMER/clean-copy.nvim) 在独立仓库维护，由 `lazy-lock.json` 锁定版本。Visual 模式选择代码后按 `空格 cy`；`:CleanCopy` 处理整个 buffer，`:[range]CleanCopy` 处理指定行。普通 `y` 和源 buffer 保持原样。执行 `:DotfilesTSInstall` 安装已配置的 parser，包含 SQL、C/C++、JS/TS/JSX/TSX、Rust、Go、Python、PHP、C#、HTML、CSS、Java、Vue 和 Lua；混合语言文件还需要对应嵌入语言的 parser。缺少 parser 时会提示，不会在复制时自动安装。系统剪贴板需要 `wl-copy`、`xclip`、`xsel` 或 macOS `pbcopy` 等 provider，本地寄存器仍可使用。默认保留 Python docstring 和已识别的工具指令；SQL 方言和嵌入语言限制见插件仓库文档。
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
| `sunshine` | Linux + Plasma（Wayland） | 只同步 `sunshine.conf`，使用 KWin 捕获和 VAAPI 编码；应用列表、配对数据和用户服务覆盖文件留在本机。 |

其余桌面配置和 DWM 时代的脚本为可选 Linux 包，迁移到新机器前请检查依赖的外部命令。`steam-switch.sh` 会验证账号文件，拒绝替换普通文件或目录，链接更新失败时回滚已更改的链接。壁纸脚本按原样处理文件名，仅管理自身启动的控制器和播放器，依赖 Linux util-linux（`flock`、`setsid`）及对应图形后端；私有状态目录为 `$XDG_RUNTIME_DIR/dotfiles-wallpaper`，未设置运行目录时使用 XDG 缓存目录。

## 可选 Linux 用户服务

`systemd` 包提供 aria2、macast、Ollama 和可选磁盘挂载服务。服务启用链接（`*.wants/`）由各电脑的 `systemctl --user enable` 生成，Git 不跟踪这些链接，克隆仓库不会自动启用服务。

```sh
stow -n -v -t "$HOME" systemd
stow -v -t "$HOME" systemd
systemctl --user daemon-reload
# 只启用当前电脑需要且已安装的服务，例如：
systemctl --user enable --now ollama.service
```

Ollama 默认使用 `~/Disk/OllamaModels`。要使用其他模型目录，将 `~/.config/dotfiles/ollama.env.example` 复制为同目录下的 `ollama.env`，设置 `OLLAMA_MODELS` 为实际绝对路径。这些 `.env` 文件由 Git 忽略；systemd 的 EnvironmentFile 不展开 `$HOME` 或 `~`，参见 [systemd 环境变量说明](https://github.com/systemd/systemd/blob/main/man/systemd.exec.xml)。

`udisksd.service` 是通过 UDisks 挂载本机磁盘的用户服务，区别于系统的 UDisks 守护进程。仅在需要时将 `mount.env.example` 复制为 `mount.env`，用 `lsblk -f` 查到的 UUID 填写 `DOTFILES_MOUNT_DEVICE`，再执行 `systemctl --user enable --now udisksd.service`。没有 `mount.env` 时跳过挂载；Ollama 与挂载服务同时启用时，先执行挂载。`udevadm-monitor.sh` 是可手动运行的可选监控脚本，仅处理新加入且包含文件系统的块设备，需要 `udevadm`、`stdbuf`、`awk` 和 `udisksctl`。

## 验证

在仓库根目录执行回归检查：

```sh
python -B -m unittest discover -s tests -p 'test_*.py'
nvim --headless -u NONE -i NONE -l tests/test_nvim_taglist.lua
```

Kitty/tmux 集成测试使用独立临时 socket 与 PTY，需要 Linux、tmux 和 Zsh；完整提示符测试还需要 Arch 的 Oh My Zsh/Powerlevel10k 包。桌面脚本使用临时 HOME 和模拟进程，不操作现有会话或 Steam 文件。clangd 测试需要 clangd；Taglist 测试需要已安装的插件和 Universal Ctags。缺少集成依赖时会显示跳过。
