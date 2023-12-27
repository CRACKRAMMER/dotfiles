require("zen-mode").toggle({
  window = {
    width = .85 -- width will be 85% of the editor width
  }
})

vim.keymap.set('n', '<leader>z', ':ZenMode<Return>')
require("zen-mode").close()
