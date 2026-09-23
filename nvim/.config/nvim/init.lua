require("core.options")
require("core.keymaps")
require("plugins.plugins-setup")

-- 插件
require("plugins.colors")
require("plugins.lualine")
require("plugins/nvim-tree")
require("plugins/treesitter")
require("plugins/lsp")
require("plugins/cmp")
require("plugins/comment")
require("plugins/autopairs")
require("plugins/bufferline")
require("plugins/gitsigns")
require("plugins/telescope")
require("plugins/taglist")
require("plugins/zen-mode")

local local_config = vim.fn.stdpath("config") .. "/lua/local.lua"
if vim.uv.fs_stat(local_config) then
  dofile(local_config)
end
