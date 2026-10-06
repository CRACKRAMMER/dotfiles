vim.g.Tlist_Use_Right_Window = 1
vim.g.Tlist_GainFocus_On_ToggleOpen = 1

local M = {}

local function ctags_command()
  if vim.g.Tlist_Ctags_Cmd ~= nil then
    local configured = vim.g.Tlist_Ctags_Cmd
    -- Taglist documents quoted executable paths for directories with spaces.
    local executable = configured:match('^"(.*)"$') or configured:match("^'(.*)'$") or configured
    if vim.fn.executable(executable) == 1 then
      return executable:find("%s") and vim.fn.shellescape(executable) or configured
    end
    return nil
  end

  for _, command in ipairs({ "ctags", "ctags-universal", "exuberant-ctags", "universal-ctags", "exctags" }) do
    if vim.fn.executable(command) == 1 then
      return command
    end
  end
end

local function call_taglist(name)
  local command = ctags_command()
  if not command then
    vim.notify("Taglist requires Universal Ctags. Install it or set g:Tlist_Ctags_Cmd to its executable.", vim.log.levels.WARN)
    return false
  end
  vim.g.Tlist_Ctags_Cmd = command

  -- Vim remembers attempted autoloads, including a load that stopped because
  -- Ctags was absent. Source it explicitly after the dependency becomes ready.
  if vim.fn.exists("*" .. name) == 0 then
    vim.cmd("runtime autoload/taglist.vim")
  end
  if vim.fn.exists("*" .. name) == 0 then
    vim.notify("Taglist is unavailable. Install or restore the taglist plugin.", vim.log.levels.ERROR)
    return false
  end

  vim.fn[name]()
  return true
end

function M.toggle()
  return call_taglist("taglist#Tlist_Window_Toggle")
end

-- Keep the existing shortcut and command names; dependency checks happen when
-- used, so installing Ctags does not require restarting Neovim.
vim.api.nvim_create_user_command("TlistToggle", M.toggle, { bar = true, force = true })
vim.api.nvim_create_user_command("TlistOpen", function()
  call_taglist("taglist#Tlist_Window_Open")
end, { bar = true, force = true })

return M
