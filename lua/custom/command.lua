--- === New Scratch Buffer ===
local new_scratch_buf = function()
  vim.cmd 'enew'
  vim.cmd 'setlocal buftype=nofile bufhidden=hide noswapfile'
  vim.cmd 'setlocal filetype=markdown'
end
vim.api.nvim_create_user_command('NewScratch', new_scratch_buf, { desc = 'Start a scratch buffer' })

local yank_group = vim.api.nvim_create_augroup('HighlightYank', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = yank_group,
  callback = function() vim.highlight.on_yank() end,
})

vim.api.nvim_create_user_command('CopyFilePath', function() vim.fn.setreg('+', vim.fn.expand '%:p') end, { nargs = 0 })
