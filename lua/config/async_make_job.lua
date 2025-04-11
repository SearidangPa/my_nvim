local async_job = {}
local map = vim.keymap.set
local linter_ns = vim.api.nvim_create_namespace 'linter'

async_job.make_all = function()
  if vim.bo.filetype ~= 'go' then
    return
  end
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j all' }
  else
    cmd = { 'make', '-j', 'all' }
  end

  local fidget = require 'fidget'

  local fidget_handle = fidget.progress.handle.create {
    title = table.concat(cmd, ' '),
    lsp_client = {
      name = 'build',
    },
  }
  local make_all_ns = vim.api.nvim_create_namespace 'make_all'

  require('config.util_job').start_job { cmd = cmd, fidget_handle = fidget_handle, ns = make_all_ns }
end

async_job.make_lint = function()
  local start_job = require('config.util_job').start_job
  if vim.bo.filetype ~= 'go' then
    return
  end
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j lint' }
  else
    cmd = { 'make', '-j', 'lint' }
  end
  start_job { cmd = cmd, ns = linter_ns }
end

vim.api.nvim_create_user_command('ClearQuickFix', function()
  vim.fn.setqflist({}, 'r')
  vim.diagnostic.reset(linter_ns)
end, {})

vim.api.nvim_create_user_command('GoModTidy', function() require('config.util_job').start_job { cmd = 'go mod tidy' } end, {})

-- vim.api.nvim_create_user_command('MakeAll', async_job.make_all, {})
vim.api.nvim_create_user_command('MakeAll', function()
  package['config.util_job'] = nil
  async_job.make_all()
end, {})

vim.api.nvim_create_user_command('MakeLint', async_job.make_lint, {})
map('n', '<leader>ma', ':MakeAll<CR>', { desc = '[M}ake [A]ll in the background' })
map('n', '<leader>ml', ':MakeLint<CR>', { desc = '[M]ake [L]int' })

return async_job
