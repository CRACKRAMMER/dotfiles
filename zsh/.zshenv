typeset -U path
path=($path "$HOME/.local/bin" "$HOME/.local/scripts")

export LANG=${LANG:-en_US.UTF-8}

# export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# export DRI_PRIME=0
# export MANGOHUD=1
# export WLR_NO_HARDWARE_CURSORS=1
# export GDK_SCALE=2

export EDITOR=${EDITOR:-nvim}
if [[ -z ${BROWSER:-} ]]; then
    case $OSTYPE in
        darwin*) export BROWSER=open ;;
        *) command -v xdg-open >/dev/null 2>&1 && export BROWSER=xdg-open ;;
    esac
fi

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

# export GOPATH=$XDG_DATA_HOME/go
export GOPATH=${GOPATH:-$HOME/Code/GO}
[[ $OSTYPE == linux* ]] && export WINEPREFIX=${WINEPREFIX:-$HOME/Wine}
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

export LS_COLORS='rs=0:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44:ex=01;32:';
