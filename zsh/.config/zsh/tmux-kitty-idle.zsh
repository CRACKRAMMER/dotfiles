# A PID match prevents stale prompt state from surviving a respawned tmux pane.
if [[ -o interactive && -n ${TMUX:-} && -n ${TMUX_PANE:-} ]]; then
  _dotfiles_kitty_tmux_trace() {
    [[ ${DOTFILES_KITTY_TMUX_DEBUG:-0} == 1 ]] || return 0
    print -r -- "$1" 2>/dev/null >> "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/tmux_close.log"
    return 0
  }

  _dotfiles_kitty_tmux_busy() {
    command tmux set-option -p -t "$TMUX_PANE" @kitty_idle_shell_pid 0 2>/dev/null ||
      _dotfiles_kitty_tmux_trace "busy hook: tmux set-option failed for shell $$"
    return 0
  }

  _dotfiles_kitty_tmux_helpers() {
    local -a -U helper_groups
    local helper_pid
    # Prompt workers are not user jobs. Report only known workers owned by this
    # shell; the watcher still checks their real process groups and session.
    if [[ ${_p9k__worker_shell_pid:-} == $$ && ${_p9k__worker_pid:-} == <1-> ]]; then
      helper_groups+=("$_p9k__worker_pid")
    fi
    if [[ ${_GITSTATUS_CLIENT_PID_POWERLEVEL9K:-} == $$ && ${GITSTATUS_DAEMON_PID_POWERLEVEL9K:-} == <1-> ]]; then
      helper_groups+=("$GITSTATUS_DAEMON_PID_POWERLEVEL9K")
    fi
    if [[ -o monitor ]] && (( ${+parameters[_OMZ_ASYNC_PIDS]} )); then
      for helper_pid in "${(@v)_OMZ_ASYNC_PIDS}"; do
        [[ $helper_pid == <1-> ]] && helper_groups+=("$helper_pid")
      done
    fi
    command tmux set-option -p -t "$TMUX_PANE" @kitty_prompt_helper_pgroups "$$ ${(j: :)helper_groups}" 2>/dev/null ||
      _dotfiles_kitty_tmux_trace "helper hook: tmux set-option failed for shell $$"
    return 0
  }

  _dotfiles_kitty_tmux_prompt() {
    local idle_pid=0
    [[ -z "$(jobs -p)" ]] && idle_pid=$$
    command tmux set-option -p -t "$TMUX_PANE" @kitty_idle_shell_pid "$idle_pid" 2>/dev/null ||
      _dotfiles_kitty_tmux_trace "prompt hook: tmux set-option failed for shell $$"
    _dotfiles_kitty_tmux_helpers
    return 0
  }

  # Record state before prompt/theme plugins, and keep re-sourcing idempotent.
  typeset -ga preexec_functions precmd_functions
  preexec_functions=(_dotfiles_kitty_tmux_busy ${preexec_functions:#_dotfiles_kitty_tmux_busy})
  precmd_functions=(_dotfiles_kitty_tmux_prompt ${precmd_functions:#_dotfiles_kitty_tmux_prompt})
  # P10k can start its helpers after precmd. Refresh once ZLE enters the prompt,
  # without changing the busy/idle marker (vared also invokes line-init).
  autoload -Uz add-zle-hook-widget
  add-zle-hook-widget -d line-init _dotfiles_kitty_tmux_helpers
  add-zle-hook-widget line-init _dotfiles_kitty_tmux_helpers
fi
