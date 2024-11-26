vim.api.nvim_create_user_command('Make', function()
  if vim.fn.has 'win32' == 1 then
    vim.cmd [[!"C:\Program Files\Git\bin\bash.exe" -c "make -j all"]]
  else
    vim.cmd [[!make -j all]]
  end
end, {})
vim.keymap.set('n', '<leader>m', ':Make<CR>', { desc = 'Run make' })

vim.api.nvim_create_user_command('Tidy', function()
  vim.cmd [[!go mod tidy]]
end, { desc = 'Run go mod tidy' })

vim.keymap.set('n', '<leader>gt', ':Tidy<CR>', { desc = 'Run go mod tidy' })

-- LspStop
vim.keymap.set('n', '<leader>gs', ':LspStop', { desc = 'Stop LSP' })

-- lua
vim.api.nvim_create_user_command('Source', 'source %', {})
vim.api.nvim_set_keymap('n', '<leader>x', ':Source<CR>', { noremap = true, silent = true, desc = 'source %' })

-- lsp
vim.api.nvim_set_keymap('n', '<m-r>', ':LspRestart<CR>', { desc = 'Restart LSP' })
vim.api.nvim_set_keymap('n', '<m-q>', ':LspStop', { desc = 'Stop LSP' })

-- terminal
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

if vim.fn.has 'win32' == 1 then
  vim.keymap.set('n', '<leader>tt', '<cmd>vsp<CR><cmd>term powershell.exe<CR>a', { desc = 'Open terminal' })
else
  vim.keymap.set('n', '<leader>tt', '<cmd>vsp<CR><cmd>term<CR>a', { desc = 'Open terminal' })
end

return {}
