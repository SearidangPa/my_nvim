vim.api.nvim_set_keymap('i', '<m-p>', '()<Esc>a', { noremap = true, silent = true, desc = 'Insert parentheses' })

-- add empty line
vim.api.nvim_set_keymap('n', '<m-k', 'o<Esc>', { noremap = true, silent = true, desc = 'Insert empty line above' })
vim.api.nvim_set_keymap('n', '<m-j', 'O<Esc>', { noremap = true, silent = true, desc = 'Insert empty line below' })

return {}
