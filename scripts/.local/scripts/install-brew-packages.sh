#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
    printf 'Homebrew is required: https://brew.sh/\n' >&2
    exit 1
fi

brew install git stow zsh neovim tmux ripgrep fzf tree-sitter-cli node fd zoxide fastfetch zsh-autosuggestions zsh-syntax-highlighting aria2 yazi bottom lazygit mpv
