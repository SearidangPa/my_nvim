-- window navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- paste
vim.api.nvim_set_keymap('v', 'p', '"_dP', { noremap = true, silent = true })
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

-- empty parentheses
vim.api.nvim_set_keymap('i', '<M-p>', '()<Esc>a', { noremap = true, silent = true, desc = 'Insert parentheses' })

-- delete forward
vim.keymap.set('i', '<C-D>', '<Del>')

-- Map 'q' in normal mode to enter insert mode
vim.keymap.set('n', '``', 'i', { noremap = true, silent = true, desc = 'Enter insert mode' })

-- Map 'q' in insert mode to exit back to normal mode
vim.keymap.set('i', '``', '<Esc>', { noremap = true, silent = true, desc = 'Exit insert mode' })

return {}
