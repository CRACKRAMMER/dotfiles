local opt = vim.opt

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "typescriptreact", "rust", "lua", "json", "css", "scss", "vue" },
  callback = function(event)
    vim.bo[event.buf].shiftwidth = 2
    vim.bo[event.buf].softtabstop = 2
  end,
})

opt.relativenumber = true
opt.number = true

vim.scriptencoding = 'utf-8'
opt.encoding = 'utf-8'
opt.fileencoding = 'utf-8'
opt.fileencodings = 'utf-8,gbk'

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

opt.wrap = false

opt.autoread = true
vim.bo.autoread = true

opt.scrolloff = 5
opt.sidescrolloff = 5

opt.hlsearch = true
opt.incsearch = true
opt.cursorline = true

opt.mouse:append("a")

local has_clipboard = vim.uv.os_uname().sysname == "Darwin"
  or vim.fn.executable("wl-copy") == 1
  or vim.fn.executable("xclip") == 1
  or vim.fn.executable("xsel") == 1
if has_clipboard then
  opt.clipboard:append("unnamedplus")
end

opt.splitright = true
opt.splitbelow = true

opt.ignorecase = true
opt.smartcase = true

opt.termguicolors = true
opt.signcolumn = "yes"
opt.laststatus = 3
opt.showmode = false
opt.winborder = "rounded"
opt.fillchars = { eob = " " }
opt.pumheight = 12
