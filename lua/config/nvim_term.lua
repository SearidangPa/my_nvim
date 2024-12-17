vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
if vim.fn.has 'win32' == 1 then
  vim.keymap.set('n', '<leader>tt', '<cmd>term powershell.exe<CR>a', { desc = 'Open terminal' })
else
  vim.keymap.set('n', '<leader>tt', '<cmd>term<CR>a', { desc = 'Open terminal' })
end

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

local job_id = 0
vim.keymap.set('n', '<leader>bt', function()
  vim.cmd.vnew()
  if vim.fn.has 'win32' == 1 then
    vim.cmd.term 'powershell.exe'
  else
    vim.cmd.term()
  end

  vim.cmd.wincmd 'J'
  vim.api.nvim_win_set_height(0, 15)
  vim.api.nvim_feedkeys('i', 'n', true)
  job_id = vim.bo.channel
end)

vim.keymap.set('n', '<leader>xst', function()
  vim.fn.chansend(job_id, 're;st\n')
end, { desc = 'Send re;st to terminal' })

return {}
