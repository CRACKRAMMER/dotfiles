require("bufferline").setup({
  options = {
    diagnostics = "nvim_lsp",
    separator_style = "slant",
    indicator = { style = "underline" },
    show_buffer_close_icons = false,
    offsets = {
      {
        filetype = "NvimTree",
        text = "Explorer",
        highlight = "Directory",
        text_align = "left",
      },
    },
  },
})
