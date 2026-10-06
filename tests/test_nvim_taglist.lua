-- Run with: nvim --headless -u NONE -i NONE -l tests/test_nvim_taglist.lua
-- Requires the installed Taglist plugin and Universal Ctags. Tests use their
-- real implementations, while changing PATH only inside this Neovim process.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local plugin_dir = vim.env.DOTFILES_TAGLIST_DIR or (vim.fn.stdpath("data") .. "/lazy/taglist")
local executable
for _, candidate in ipairs({ "ctags", "ctags-universal", "universal-ctags", "exuberant-ctags", "exctags" }) do
  if vim.fn.executable(candidate) == 1 then
    executable = vim.fn.exepath(candidate)
    break
  end
end
assert(executable, "Install Universal Ctags before running this integration test")
assert(vim.fn.filereadable(plugin_dir .. "/autoload/taglist.vim") == 1, "Taglist plugin is missing")
vim.opt.runtimepath:prepend(plugin_dir)
vim.cmd("runtime plugin/taglist.vim")

local messages = {}
vim.notify = function(message)
  messages[#messages + 1] = message
end
local original_path = vim.env.PATH
local empty_path = vim.fn.tempname()
vim.fn.mkdir(empty_path, "p")
vim.env.PATH = empty_path
vim.g.Tlist_Ctags_Cmd = nil

-- Reproduce the original failure before loading the repaired configuration.
local loaded = pcall(vim.fn["taglist#Tlist_Window_Toggle"])
assert(not loaded, "An initial autoload without Ctags should fail")
local taglist = dofile(root .. "/nvim/.config/nvim/lua/plugins/taglist.lua")
local windows = #vim.api.nvim_list_wins()
assert(not taglist.toggle(), "Missing dependency should return false")
vim.cmd("TlistToggle")
vim.cmd("TlistOpen")
assert(#vim.api.nvim_list_wins() == windows, "Missing dependency must not create a window")
assert(#messages == 3 and messages[1]:find("Universal Ctags", 1, true), "Missing dependency should give a useful warning")
print("PASS Taglist missing dependency produces a warning without E117")

local sample = vim.fn.tempname() .. ".c"
vim.fn.writefile({ "int dotfiles_test_symbol(void) { return 0; }" }, sample)
vim.cmd.edit(vim.fn.fnameescape(sample))
vim.bo.filetype = "c"
vim.env.PATH = original_path
vim.cmd("TlistToggle")
assert(#vim.api.nvim_list_wins() == windows + 1, "Installing Ctags should permit opening without a restart")
assert(vim.fn.exists("*taglist#Tlist_Window_Toggle") == 1, "Failed autoload should have recovered")
assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, true), "\n"):find("dotfiles_test_symbol", 1, true), "Real Ctags should list the sample symbol")
vim.cmd("TlistToggle")
assert(#vim.api.nvim_list_wins() == windows, "Toggling should close the Taglist window")
print("PASS Taglist recovers from a failed autoload in the same Neovim process")

vim.env.PATH = empty_path
vim.g.Tlist_Ctags_Cmd = executable
vim.cmd("TlistOpen")
assert(#vim.api.nvim_list_wins() == windows + 1, "An explicit executable path should work outside PATH")
vim.cmd("TlistToggle")
vim.env.PATH = original_path
print("PASS Taglist honors an explicit Ctags executable path")

local spaced_path = empty_path .. "/ctags with spaces"
assert(vim.uv.fs_symlink(executable, spaced_path))
vim.g.Tlist_Ctags_Cmd = vim.fn.shellescape(spaced_path)
vim.cmd("TlistOpen")
assert(#vim.api.nvim_list_wins() == windows + 1, "Quoted executable paths should work")
vim.cmd("TlistToggle")
vim.fn.delete(spaced_path)
vim.fn.delete(sample)
vim.fn.delete(empty_path, "d")
print("PASS Taglist honors an executable path containing spaces")
