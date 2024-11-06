vim.api.nvim_set_keymap('i', '<m-p>', '()<Esc>a', { noremap = true, silent = true, desc = 'Insert parentheses' })

-- add empty line
vim.api.nvim_set_keymap('n', '<m-k>', 'O<Esc>j', { noremap = true, silent = true, desc = 'Insert empty line above' })
vim.api.nvim_set_keymap('n', '<m-j>', 'o<Esc>k', { noremap = true, silent = true, desc = 'Insert empty line below' })

return {}
