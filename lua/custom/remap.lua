local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

map('v', 'J', ":m '>+1<CR>gv=gv") -- move line down
map('v', 'K', ":m '<-2<CR>gv=gv") -- move line up
map('n', 'n', 'nzzzv')

map('n', '<C-u>', '<C-u>zz')
map('n', '<C-d>', '<C-d>zz')
map('n', '<PageUp>', '<C-u>zz')
map('n', '<PageDown>', '<C-d>zz')

map('x', '<leader>p', [["_dP]], map_opt '[P]aste without overwriting the clipboard')
