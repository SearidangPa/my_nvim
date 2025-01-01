local output = {}
local errors = {}

vim.api.nvim_create_user_command('MakeAll', function()
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j all' }
  else
    cmd = { 'make', '-j', 'all' }
  end
  _, output, errors = Start_job { cmd = cmd }
end, {})

vim.api.nvim_create_user_command('GoModTidy', function()
  local cmd = { 'go', 'mod', 'tidy' }
  _, output, errors = Start_job { cmd = cmd }
end, {})

local linter_ns = vim.api.nvim_create_namespace 'cloud_drive_linter'
vim.api.nvim_create_user_command('MakeLint', function()
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j lint' }
  else
    cmd = { 'make', '-j', 'lint-unix' }
  end
  _, output, errors = Start_job { cmd = cmd, ns = linter_ns }
end, {})

vim.api.nvim_create_user_command('ClearQuickFix', function()
  vim.fn.setqflist({}, 'r')
  vim.diagnostic.reset(linter_ns)
end, {})

vim.api.nvim_create_user_command('ViewOutput', function()
  local buf, _ = Create_floating_window()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
end, {})

vim.api.nvim_create_user_command('ViewErrors', function()
  local buf = Create_floating_window()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, errors)
end, {})

vim.keymap.set('n', '<localleader><localleader>', '<cmd>source % <CR>', {
  noremap = true,
  silent = false,
  desc = 'Source this lua file',
})

vim.keymap.set('n', '<leader>ma', ':MakeAll<CR>', { desc = '[M}ake [A]ll in the background' })
vim.keymap.set('n', '<leader>mt', ':GoModTidy<CR>', { desc = '[M]ake [T]idy' })
vim.keymap.set('n', '<leader>ml', ':MakeLint<CR>', { desc = '[M]ake [L]int' })

vim.keymap.set('n', '<leader>rm', ':messages<CR>', { desc = '[R]ead [M]essages' })

return {}
