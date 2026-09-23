local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  local result = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("lazy.nvim bootstrap failed: " .. result)
  end
end
vim.opt.rtp:prepend(lazypath)


local plugins = {
  "folke/tokyonight.nvim", -- 主题
  "nvim-lualine/lualine.nvim",  -- 状态栏
  "nvim-tree/nvim-tree.lua",  -- 文档树
  "nvim-tree/nvim-web-devicons", -- 文档树图标

  "christoomey/vim-tmux-navigator", -- 用ctl-hjkl来定位窗口
  { "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false, build = ":TSUpdate" },

  { "mason-org/mason.nvim", lazy = false },
  { "neovim/nvim-lspconfig", lazy = false },
  { "mason-org/mason-lspconfig.nvim", dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" } },

      -- 自动补全
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "L3MON4D3/LuaSnip", -- snippets引擎，不装这个自动补全会出问题
  "saadparwaiz1/cmp_luasnip",
  "rafamadriz/friendly-snippets",
  "hrsh7th/cmp-path", -- 文件路径

  "numToStr/Comment.nvim", -- gcc和gc注释
  "windwp/nvim-autopairs", -- 自动补全括号

  "akinsho/bufferline.nvim", -- buffer分割线
  "lewis6991/gitsigns.nvim", -- 左则git提示
  { "h-hg/fcitx.nvim", cond = function()
    return vim.fn.executable("fcitx5-remote") == 1 or vim.fn.executable("fcitx-remote") == 1
  end },

  "ap/vim-css-color",
  "yegappan/taglist",
  'tpope/vim-surround',
  'tpope/vim-repeat',
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },

  {
    'nvim-telescope/telescope.nvim', -- tag = '0.1.5', -- 文件检索
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  -- Lua
  {
    "folke/zen-mode.nvim",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  },

}
require("lazy").setup(plugins, { rocks = { enabled = false } })
