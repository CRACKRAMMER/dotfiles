require("lualine").setup({
  options = {
    theme = "tokyonight",
    globalstatus = true,
    component_separators = { left = "│", right = "│" },
    section_separators = { left = "", right = "" },
    disabled_filetypes = { statusline = { "NvimTree" } },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "diagnostics", "encoding", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
})
