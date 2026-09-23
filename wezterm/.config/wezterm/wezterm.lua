local wezterm = require("wezterm")
return {
    font = wezterm.font("FiraCode Nerd Font"),
    font_size = 18,
    hide_tab_bar_if_only_one_tab = true,
    -- window_background_opacity = 0.9,
    window_padding = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4,
    },
    -- Tokyo Night Moon, matching Neovim and tmux.
    colors = {
        foreground = '#c8d3f5',
        background = '#222436',

        cursor_bg = '#82aaff',
        cursor_fg = '#1e2030',
        cursor_border = '#82aaff',

        selection_fg = '#c8d3f5',
        selection_bg = '#3b4261',

        ansi = {
            '#1e2030',
            '#ff757f',
            '#c3e88d',
            '#ffc777',
            '#82aaff',
            '#fca7ea',
            '#86e1fc',
            '#c8d3f5',
        },
        brights = {
            '#636da6',
            '#ff8d94',
            '#c7fb6d',
            '#ffd8ab',
            '#9ab8ff',
            '#caabff',
            '#b2ebff',
            '#ffffff',
        },
    },
}
