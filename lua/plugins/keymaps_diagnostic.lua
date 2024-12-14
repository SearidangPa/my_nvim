local function toggle_quickfix()
  if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix == 1 then
    vim.cmd 'cclose'
  else
    vim.cmd 'copen'
  end
end

vim.keymap.set('n', '<leader>qf', function()
  vim.diagnostic.setqflist()
  vim.cmd 'copen'
end, { desc = 'Fill the Quickfix list with diagnostics' })
vim.keymap.set('n', '<leader>ql', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('n', '<leader>qn', ':cnext<CR>', { desc = 'Next Quickfix item' })
vim.keymap.set('n', '<leader>qp', ':cprevious<CR>', { desc = 'Previous Quickfix item' })
vim.keymap.set('n', ']g', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
vim.keymap.set('n', '[g', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })

vim.keymap.set('n', '<leader>qc', ':cclose<CR>', { desc = 'Close Quickfix window' })
vim.keymap.set('n', '<leader>tq', toggle_quickfix, { desc = 'toggle diagnostic windows' })

vim.keymap.set('n', '<leader>qo', function()
  vim.diagnostic.open_float()
end, { desc = 'Open diagnostic float' })

return {}
