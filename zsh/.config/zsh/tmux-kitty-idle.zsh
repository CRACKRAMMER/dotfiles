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

  _dotfiles_kitty_tmux_prompt() {
    local idle_pid=0
    [[ -z "$(jobs -p)" ]] && idle_pid=$$
    command tmux set-option -p -t "$TMUX_PANE" @kitty_idle_shell_pid "$idle_pid" 2>/dev/null ||
      _dotfiles_kitty_tmux_trace "prompt hook: tmux set-option failed for shell $$"
    return 0
  }

  # Record state before prompt/theme plugins, and keep re-sourcing idempotent.
  typeset -ga preexec_functions precmd_functions
  preexec_functions=(_dotfiles_kitty_tmux_busy ${preexec_functions:#_dotfiles_kitty_tmux_busy})
  precmd_functions=(_dotfiles_kitty_tmux_prompt ${precmd_functions:#_dotfiles_kitty_tmux_prompt})
fi
