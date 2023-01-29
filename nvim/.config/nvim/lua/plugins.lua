vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'sainnhe/everforest'
  use 'glepnir/galaxyline.nvim'
  use 'neovim/nvim-lspconfig'
  use 'williamboman/nvim-lsp-installer'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/nvim-cmp'
  use 'L3MON4D3/LuaSnip'
  use 'saadparwaiz1/cmp_luasnip'
  use 'honza/vim-snippets'
  use 'yaegassy/coc-html-css-support'
  use 'onsails/lspkind-nvim' 
  use 'kevinhwang91/rnvimr'
  use 'mhartington/formatter.nvim'
  use 'aca/emmet-ls'
  use 'tpope/vim-surround'
  use 'tpope/vim-repeat'
  use {
      'nvim-treesitter/nvim-treesitter',
      run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
  }
  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-telescope/telescope-file-browser.nvim'
  use 'kyazdani42/nvim-web-devicons'
  use 'kyazdani42/nvim-tree.lua'
  use 'yegappan/taglist'

  use 'rmagatti/alternate-toggler'
  use 'windwp/nvim-autopairs'
  use 'windwp/nvim-ts-autotag'
  use 'numToStr/Comment.nvim'
  use 'wellle/targets.vim'
  use 'mg979/vim-visual-multi'
  use 'voldikss/vim-floaterm'

end)
