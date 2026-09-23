local treesitter = require("nvim-treesitter")

local parsers = {
  "bash", "c", "cpp", "css", "html", "javascript", "json", "lua",
  "markdown", "markdown_inline", "python", "rust", "tsx", "typescript",
  "vim", "vimdoc",
}

-- Run this after installing the CLI on a new machine. Parser installation is
-- explicit so opening Neovim offline does not start network downloads.
vim.api.nvim_create_user_command("DotfilesTSInstall", function()
  treesitter.install(parsers)
end, {})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "sh", "c", "cpp", "css", "html", "javascript", "json", "lua",
    "markdown", "python", "rust", "typescript", "typescriptreact", "vim", "vimdoc",
  },
  callback = function(event)
    pcall(vim.treesitter.start, event.buf)
  end,
})
