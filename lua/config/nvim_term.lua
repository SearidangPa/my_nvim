vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
if vim.fn.has 'win32' == 1 then
  vim.keymap.set('n', '<leader>tt', '<cmd>term powershell.exe<CR>a', { desc = 'Open terminal' })
else
  vim.keymap.set('n', '<leader>tt', '<cmd>term<CR>a', { desc = 'Open terminal' })
end

return {}
