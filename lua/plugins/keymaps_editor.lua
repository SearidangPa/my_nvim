-- window navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- delete forward
vim.keymap.set('i', '<C-D>', '<Del>')

-- paste
vim.api.nvim_set_keymap('n', 'dD', '"_dd', { noremap = true, silent = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
-- add empty line
vim.api.nvim_set_keymap('n', '<leader>k', 'O<Esc>j', { noremap = true, silent = true, desc = 'Insert empty line above' })
vim.api.nvim_set_keymap('n', '<leader>j', 'o<Esc>k', { noremap = true, silent = true, desc = 'Insert empty line below' })

-- exit mode
vim.keymap.set('n', '``', 'i', { noremap = true, silent = true, desc = 'Enter insert mode' })
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true, silent = true, desc = 'Exit insert mode' })

return {}
