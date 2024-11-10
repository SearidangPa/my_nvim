vim.api.nvim_create_user_command('Make', function()
  if vim.fn.has 'win32' == 1 then
    vim.cmd [[!"C:\Program Files\Git\bin\bash.exe" -c "rm bin/cloud-drive.exe && make -j all"]]
  else
    vim.cmd [[!make -j all]]
  end
end, {})

vim.keymap.set('n', '<leader>m', ':Make<CR>', { desc = 'Run make' })

vim.api.nvim_create_user_command('Tidy', function()
  vim.cmd [[!go mod tidy]]
end, { desc = 'Run go mod tidy' })

vim.keymap.set('n', '<m-t>', ':Tidy<CR>', { desc = 'Run go mod tidy' })

-- lua
vim.api.nvim_create_user_command('Source', 'source %', {})
vim.api.nvim_set_keymap('n', '<leader>x', ':Source<CR>', { noremap = true, silent = true, desc = 'source %' })

-- lsp
vim.api.nvim_set_keymap('n', '<m-r>', ':LspRestart<CR>', { desc = 'Restart LSP' })
vim.api.nvim_set_keymap('n', '<m-q>', ':LspStop', { desc = 'Stop LSP' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

return {}
