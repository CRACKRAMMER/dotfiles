local opts = { noremap=true, silent=true }
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)

local on_attach = function(client, bufnr)
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', '<leader>k', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
end

local lsp_flags = {
  debounce_text_changes = 150,
}
require("nvim-lsp-installer").setup {}
require('lspconfig')['ccls'].setup{
    on_attach = on_attach,
    root_dir = require("lspconfig.util").root_pattern('Makefile', 'compile_commands.json', '.ccls', '.git', '.'),
    init_options = {
        index = {
            threads = 0,
        },
        clang = {
            extraArgs = {"-isystem", "/usr/local/include", "-isystem", "./Header"},
        },
        cache = {
            directory = "/tmp/ccls-cache",
        },
        cacheFormat = "json",
  }
}
require('lspconfig')['pyright'].setup{
    on_attach = on_attach,
}
require('lspconfig')['gopls'].setup{
    on_attach = on_attach,
}
require('lspconfig')['jdtls'].setup{
    on_attach = on_attach,
    cmd = {
        "jdtls",
        "-configuration",
        "/home/xiechengan/.cache/jdtls/config",
        "-data",
        vim.fn.getcwd().."/src"
    }
}
require('lspconfig')['tsserver'].setup{
    on_attach = on_attach,
}
require('lspconfig')['rust_analyzer'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
    -- Server-specific settings...
    settings = {
      ["rust-analyzer"] = {}
    }
}
