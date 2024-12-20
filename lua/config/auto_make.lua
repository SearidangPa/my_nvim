vim.api.nvim_create_user_command('MakeAll', function()
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j all' }
  else
    cmd = { 'make', '-j', 'all' }
  end
  Start_job { cmd = cmd }
end, {})

vim.api.nvim_create_user_command('GoModTidy', function()
  local cmd = { 'go', 'mod', 'tidy' }
  Start_job { cmd = cmd }
end, {})

vim.api.nvim_create_user_command('ViewOutput', function()
  local buf, _ = Create_floating_window()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
end, {})

vim.api.nvim_create_user_command('ViewErrors', function()
  local buf = Create_floating_window()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, errors)
end, {})

vim.keymap.set('n', '<leader>xx', '<cmd>source % <CR>', {
  noremap = true,
  silent = true,
  desc = 'source this lua file',
})

vim.keymap.set('n', '<leader>rm', '<cmd>messages<CR>', { desc = 'read messages' })
vim.keymap.set('n', '<leader>mc', ':messages clear<CR>', { desc = '[C]lear [m]essages' })
vim.keymap.set('n', '<leader>ma', ':Make<CR>', { desc = 'Run make all in the background' })

return {}
