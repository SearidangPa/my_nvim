local async_job = {}

---@param cmd string
---@param fidget_name string
local function create_fidget_handle(cmd, fidget_name)
  assert(cmd, 'cmd is required')
  assert(fidget_name, 'fidget_name is required')
  local fidget = require 'fidget'
  return fidget.progress.handle.create {
    title = cmd,
    lsp_client = {
      name = fidget_name,
    },
  }
end

async_job.make_all = function()
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j all' }
  else
    cmd = 'make -j all'
  end
  local make_all_ns = vim.api.nvim_create_namespace 'make_all'
  local fidget_handle = create_fidget_handle(cmd, 'make_all')
  require('config.util_job').start_job { cmd = cmd, fidget_handle = fidget_handle, ns = make_all_ns }
end

async_job.make_lint = function()
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j lint' }
  else
    cmd = 'make -j lint'
  end
  local linter_ns = vim.api.nvim_create_namespace 'linter'
  local fidget_handle = create_fidget_handle(cmd, 'linter')
  require('config.util_job').start_job { cmd = cmd, fidget_handle = fidget_handle, ns = linter_ns }
end

async_job.go_mod_tidy = function()
  local cmd = 'go mod tidy'
  local go_mod_tidy_ns = vim.api.nvim_create_namespace 'go_mod_tidy'
  local fidget_handle = create_fidget_handle(cmd, 'go_mod_tidy')
  require('config.util_job').start_job { cmd = cmd, fidget_handle = fidget_handle, ns = go_mod_tidy_ns }
end

vim.api.nvim_create_user_command('GoModTidy', async_job.go_mod_tidy, {})
vim.api.nvim_create_user_command('MakeAll', async_job.make_all, {})
vim.api.nvim_create_user_command('MakeLint', async_job.make_lint, {})
vim.api.nvim_create_user_command('QuickfixClear', function() vim.fn.setqflist({}, 'r') end, {})

local map = vim.keymap.set
map('n', '<leader>ma', ':MakeAll<CR>', { desc = '[M}ake [A]ll in the background' })
map('n', '<leader>ml', ':MakeLint<CR>', { desc = '[M]ake [L]int' })

return async_job
