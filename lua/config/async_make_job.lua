local M = {}
local map = vim.keymap.set
local linter_ns = vim.api.nvim_create_namespace 'linter'
local start_job = require('config.util_job').start_job

M.make_all = function()
  if vim.bo.filetype ~= 'go' then
    return
  end
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j all' }
  else
    cmd = { 'make', '-j', 'all' }
  end
  start_job { cmd = cmd }
end

M.make_lint = function()
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

vim.api.nvim_create_user_command('GoModTidy', function() start_job { cmd = 'go mod tidy' } end, {})

vim.api.nvim_create_user_command('MakeAll', M.make_all, {})
vim.api.nvim_create_user_command('MakeLint', M.make_lint, {})
map('n', '<leader>ma', ':MakeAll<CR>', { desc = '[M}ake [A]ll in the background' })
map('n', '<leader>ml', ':MakeLint<CR>', { desc = '[M]ake [L]int' })

return M
