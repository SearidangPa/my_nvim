local function toggle_quickfix()
  if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix == 1 then
    vim.cmd 'cclose'
  else
    vim.cmd 'copen'
  end
end
vim.keymap.set('n', ',,', toggle_quickfix, { desc = 'toggle diagnostic windows' })

vim.keymap.set('n', ',q', function()
  vim.diagnostic.setqflist()
  vim.cmd 'copen'
end, { desc = 'Populate the Quickfix list with diagnostics' })

-- navigate diagnostics
vim.keymap.set('n', '<leader>n', ':cnext<CR>', { desc = 'Next Quickfix item' })
vim.keymap.set('n', '<leader>p', ':cprevious<CR>', { desc = 'Previous Quickfix item' })
vim.keymap.set('n', ']g', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
vim.keymap.set('n', '[g', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<m-c>', ':cclose<CR>', { desc = 'Close Quickfix window' })

return {}
