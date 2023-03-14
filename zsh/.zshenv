PATH="$PATH:~/.local/bin:/opt/jython/bin"

# use bat as man pager
export LANG=en_US.UTF-8
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

export MANGOHUD=1
export DRI_PRIME=0

export EDITOR=nvim
export BROWSER=firefox

export XDG_CONFIG_HOME=~/.config
export XDG_DATA_HOME=~/.local/share
export XDG_CACHE_HOME=~/.cache

export GOPATH=$XDG_DATA_HOME/go

export LS_COLORS='rs=0:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44:ex=01;32:';

export WLR_NO_HARDWARE_CURSORS=1
