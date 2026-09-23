# Start tmux before loading prompt and plugins. The tmux child shell loads them once.
if [[ -o interactive && -z ${TMUX:-} && -z ${DOTFILES_NO_TMUX:-} ]] && { [[ -t 0 ]] || [[ -t 1 ]]; } && command -v tmux >/dev/null 2>&1; then
  exec tmux
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
# Path to your oh-my-zsh installation.
if [[ -z ${ZSH:-} ]]; then
  if [[ -r "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    ZSH="$HOME/.oh-my-zsh"
  elif [[ -r /usr/share/oh-my-zsh/oh-my-zsh.sh ]]; then
    ZSH=/usr/share/oh-my-zsh
  else
    ZSH="$HOME/.oh-my-zsh"
  fi
fi
export ZSH
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
mkdir -p "$ZSH_CACHE_DIR"

# export GOPROXY="https://goproxy.cn,direct"
# export GOROOT="/usr/lib/go"
# export GOSUMDB="off"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
# ZSH_THEME="avit"
p10k_theme=''
for theme_file in /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme; do
  if [[ -r "$theme_file" ]]; then
    p10k_theme=$theme_file
    break
  fi
done
if [[ -n $p10k_theme ]]; then
  ZSH_THEME=''
else
  ZSH_THEME=ys
fi

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)
if (( $+commands[fzf] )) && [[ -r "$ZSH/plugins/fzf/fzf.plugin.zsh" ]]; then
  plugins+=(fzf)
fi

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit -d "${ZSH_COMPDUMP:-$HOME/.zcompdump}"
fi

# Homebrew can provide fzf without Oh My Zsh. Load its shell integration once.
if (( $+commands[fzf] )) && (( ${plugins[(Ie)fzf]} == 0 )); then
  if fzf_shell_setup=$(fzf --zsh 2>/dev/null); then
    eval "$fzf_shell_setup"
  else
    for fzf_shell_dir in /usr/share/fzf /opt/homebrew/opt/fzf/shell /usr/local/opt/fzf/shell; do
      if [[ -r "$fzf_shell_dir/key-bindings.zsh" ]]; then
        [[ -r "$fzf_shell_dir/completion.zsh" ]] && source "$fzf_shell_dir/completion.zsh"
        source "$fzf_shell_dir/key-bindings.zsh"
        break
      fi
    done
  fi
  unset fzf_shell_setup fzf_shell_dir
fi

# fzf-tab replaces the completion menu, so load it after compinit and fzf.
fzf_tab_plugin="${ZDOTDIR:-$HOME}/.config/zsh/fzf-tab/fzf-tab.plugin.zsh"
if (( $+commands[fzf] )) && [[ -r "$fzf_tab_plugin" ]]; then
  zstyle ':completion:*' menu no
  zstyle ':completion:*:descriptions' format '[%d]'
  source "$fzf_tab_plugin"
fi
unset fzf_tab_plugin

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

for plugin_dir in /usr/share/zsh/plugins /opt/homebrew/share /usr/local/share; do
  if [[ -r "$plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
    break
  fi
done
[[ -n $p10k_theme ]] && source "$p10k_theme"
alias vi="nvim"
[[ $OSTYPE == linux* ]] && command -v vlc >/dev/null 2>&1 && alias xvlc="vlc -V x11"
command -v fastfetch >/dev/null 2>&1 && alias fetch="fastfetch"
if ! command -v docker >/dev/null 2>&1 && command -v podman >/dev/null 2>&1; then
  alias docker="podman"
fi
[[ $OSTYPE == linux* ]] && command -v wine >/dev/null 2>&1 && alias wine="env LANG=zh_CN.UTF-8 wine"

proxy () {
  local protocol=${1:-http}
  local endpoint=${2:-127.0.0.1:8888}
  [[ $protocol == socks ]] && protocol=socks5
  export http_proxy="$protocol://$endpoint"
  export https_proxy=$http_proxy
  export all_proxy=$http_proxy
  print -r -- "Proxy on: $all_proxy"
}

noproxy () {
  unset http_proxy
  unset https_proxy
  unset all_proxy
  print -r -- "Proxy off"
}

lang () {
    if [[ $LANG =~ '^en_US' ]] 
    then
        export LANG=zh_CN.UTF-8
    else
        export LANG=en_US.UTF-8
    fi
    echo $LANG
}

switchGPU () {
    if [[ $OSTYPE != linux* ]]; then
        print -u2 'switchGPU is available on Linux only'
        return 1
    fi
    if [[ -z ${DRI_PRIME:-} || ${DRI_PRIME:-0} == 0 ]]; then
        export DRI_PRIME=1
    else
        unset DRI_PRIME
    fi
    if command -v glxinfo >/dev/null 2>&1; then
        glxinfo | grep "OpenGL renderer" | cut -d':' -f2
    fi
}

[[ $- != *i* ]] && return

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keep machine-specific software and credentials out of the shared config.
local_zsh_config="${ZDOTDIR:-$HOME}/.config/zsh/local.zsh"
[[ -r "$local_zsh_config" ]] && source "$local_zsh_config"
unset local_zsh_config

# AUR installs Anaconda in /opt; Homebrew's cask uses its prefix/anaconda3.
# Skip initialization when another profile has already configured conda.
if (( ! $+functions[conda] )); then
  case $OSTYPE in
    darwin*) conda_roots=(/opt/homebrew/anaconda3 /usr/local/anaconda3) ;;
    linux*) conda_roots=(/opt/anaconda) ;;
    *) conda_roots=() ;;
  esac

  for conda_root in "${conda_roots[@]}"; do
    [[ -x "$conda_root/bin/conda" ]] || continue
    conda_hook=$("$conda_root/bin/conda" shell.zsh hook 2>/dev/null) || conda_hook=''
    if [[ -n $conda_hook ]]; then
      eval "$conda_hook"
    elif [[ -r "$conda_root/etc/profile.d/conda.sh" ]]; then
      source "$conda_root/etc/profile.d/conda.sh"
    fi
    break
  done
  unset conda_root conda_roots conda_hook
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
elif [[ -s /etc/profile.d/autojump.zsh ]]; then
  source /etc/profile.d/autojump.zsh
fi

# Syntax highlighting wraps ZLE widgets, so load it after all other plugins.
for plugin_dir in /usr/share/zsh/plugins /opt/homebrew/share /usr/local/share; do
  if [[ -r "$plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    break
  fi
done
unset plugin_dir theme_file p10k_theme
