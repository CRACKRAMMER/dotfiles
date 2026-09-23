#!/usr/bin/env bash

new_window() {
    command -v fzf >/dev/null 2>&1 || return
    pane_id=$(tmux show -gqv '@fzf_pane_id')
    [[ -n $pane_id ]] && tmux kill-pane -t $pane_id >/dev/null 2>&1
    printf -v script_path '%q' "$0"
    tmux new-window "bash $script_path do_action" >/dev/null 2>&1
}

# invoked by pane-focus-in event
update_mru_pane_ids() {
    o_data=($(tmux show -gqv '@mru_pane_ids'))
    current_pane_id=$(tmux display-message -p '#D')
    n_data=($current_pane_id)
    for i in ${!o_data[@]}; do
        [[ $current_pane_id != ${o_data[i]} ]] && n_data+=(${o_data[i]})
    done
    tmux set -g '@mru_pane_ids' "${n_data[*]}"
}

do_action() {
    trap 'tmux set -gu @fzf_pane_id' EXIT SIGINT SIGTERM
    current_pane_id=$(tmux display-message -p '#D')
    tmux set -g @fzf_pane_id $current_pane_id

    printf -v script_path '%q' "$0"
    cmd="bash $script_path panes_src"
    preview_cmd='tmux capture-pane -p -t {1} -S -100'
    last_pane_cmd='$(tmux show -gqv "@mru_pane_ids" | cut -d\  -f1)'
    selected=$(FZF_DEFAULT_COMMAND=$cmd fzf -m --preview="$preview_cmd" \
        --preview-window='down:80%' --reverse --info=inline --header-lines=1 \
        --delimiter='\s{2,}' --with-nth=2.. --nth=2.. \
        --bind="alt-p:toggle-preview" \
        --bind="ctrl-r:reload($cmd)" \
        --bind="ctrl-x:execute-silent(tmux kill-pane -t {1})+reload($cmd)" \
        --bind="ctrl-v:execute(tmux move-pane -h -t $last_pane_cmd -s {1})+accept" \
        --bind="ctrl-s:execute(tmux move-pane -v -t $last_pane_cmd -s {1})+accept" \
        --bind="ctrl-t:execute-silent(tmux swap-pane -t $last_pane_cmd -s {1})+reload($cmd)")
    (($?)) && return

    ids=()
    while IFS= read -r pane_line; do
        [[ -n $pane_line ]] && ids+=("${pane_line%% *}")
    done <<< "$selected"

    id_n=${#ids[@]}
    id1=${ids[0]}
    if ((id_n == 1)); then
        target_session=$(tmux display-message -t "$id1" -p '#{session_name}')
        target_window=$(tmux display-message -t "$id1" -p '#{session_name}:#{window_index}')
        tmux switch-client -t "$target_session"
        tmux select-window -t "$target_window"
        tmux select-pane -t "$id1"
    elif ((id_n > 1)); then
        tmux break-pane -s "$id1" || return
        for ((i=1; i<id_n; i++)); do
            tmux move-pane -t "$id1" -s "${ids[i]}" || return
        done

        if (( id_n == 2 )); then
            w_size=($(tmux display-message -p '#{window_width} #{window_height}'))
            w_wid=${w_size[0]}
            w_hei=${w_size[1]}
            if (( 9*w_wid > 16*w_hei )); then
                layout='even-horizontal'
            else
                layout='even-vertical'
            fi
        else
            layout='tiled'
        fi

        tmux select-layout -t "$id1" "$layout"
        target_session=$(tmux display-message -t "$id1" -p '#{session_name}')
        target_window=$(tmux display-message -t "$id1" -p '#{session_name}:#{window_index}')
        tmux switch-client -t "$target_session"
        tmux select-window -t "$target_window"
        tmux select-pane -t "$id1"
    fi
}

panes_src() {
    printf '%s\n' 'PANE  SESSION:WINDOW.PANE  COMMAND  DIRECTORY'
    tmux list-panes -a -F '#D  #{session_name}:#{window_index}.#{pane_index}  #{pane_current_command}  #{pane_current_path}' |
        awk -v current="$TMUX_PANE" '$1 != current'
}

"$@"
