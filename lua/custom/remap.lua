local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

map('i', '<C-D>', '<Del>', map_opt 'Delete character under the cursor')
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' }) -- exit terminal mode

-- === tag zz at the end ===
map('n', '<C-u>', '<C-u>zz')
map('n', '<C-d>', '<C-d>zz')
map('n', '<PageUp>', '<C-u>zz')
map('n', '<PageDown>', '<C-d>zz')
map('n', 'n', 'nzzzv')

-- === awesome for navigation long lines ===
map('n', 'j', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'j']], { expr = true })
map('n', 'k', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'k']], { expr = true })

-- === visual mode ===
map('v', 'J', ":m '>+1<CR>gv=gv") -- move line down
map('v', 'K', ":m '<-2<CR>gv=gv") -- move line up
map('x', 'p', [["_dP]], map_opt '[P]aste without overwriting the clipboard')

map('n', 'gk', 'O<Esc>j', map_opt 'Insert empty line above')
map('n', 'gj', 'o<Esc>k', map_opt 'Insert empty line below')

map('n', '<C-h>', '<C-w><C-h>', map_opt 'Move focus to the left window')
map('n', '<C-l>', '<C-w><C-l>', map_opt 'Move focus to the right window')
map('n', '<D-j>', '<C-w><C-j>', map_opt 'Move focus to the below window')
map('n', '<D-k>', '<C-w><C-k>', map_opt 'Move focus to the above window')
map('n', '<M-j>', '<C-w><C-j>', map_opt 'Move focus to the below window')
map('n', '<M-k>', '<C-w><C-k>', map_opt 'Move focus to the above window')
