local actions = require("telescope.actions")

function telescope_buffer_dir()
  return vim.fn.expand('%:p:h')
end

local fb_actions = require 'telescope'.extensions.file_browser.actions

require('telescope').setup{
  defaults = {
    mappings = {
      i = {
        ["esc"] = actions.close
      }
    }
  },
  layout_config={
    horizontal = {
      preview_cutoff = 100,
      preview_width = 0.6
    }
  },
  extensions = {
    file_browser={
      theme='dropdown',
      hijack_netrw=true,
      mappings={
        ['i']={
          ['<C-w>']=function() vim.cmd('normal vbd') end,
        },
        ['n']={
          ['h']=fb_actions.goto_parent_dir,
          ['/']=function()
            vim.cmd('startinsert')
          end
        }
      }
    }
  }
}

require('telescope').load_extension('file_browser')
local builtin = require('telescope.builtin')
vim.keymap.set('n', 'ff', builtin.find_files, {})
vim.keymap.set('n', 'fg', builtin.live_grep, {})
-- vim.keymap.set('n', 'fb', builtin.buffers, {})
-- vim.keymap.set('n', 'fh', builtin.help_tags, {})

vim.keymap.set('n','fb','<cmd>lua require("telescope").extensions.file_browser.file_browser({path="%:p:h",cwd=telescope_buffer_dir(),respect_git_ignore=false,hidden=true})<CR>')
