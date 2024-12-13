local opt = vim.opt

local indentfiletype = {"typescript", "typescriptreact", "rust", "lua", "json", "css", "scss", "vue"}
local function setup_typescript_indent()
  local ft = vim.bo.filetype
  for _, v in ipairs(indentfiletype)
    do
    if ft == v then
      vim.opt.shiftwidth = 2
      vim.opt.softtabstop = 2
      return
    end
  end
end
vim.api.nvim_create_autocmd("BufRead", {
  callback = setup_typescript_indent,
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

opt.clipboard:append("unnamedplus")

opt.splitright = true
opt.splitbelow = true

opt.ignorecase = true
opt.smartcase = true

opt.termguicolors = true
opt.signcolumn = "yes"
