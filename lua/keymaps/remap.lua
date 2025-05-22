local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

map('n', '<Tab>', function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('za', true, false, true), 'n', true) end, map_opt 'Toggle fold')
map('n', '<leader><BS>', ':ClearExtmarks<CR>', map_opt '[C]lear [E]xtmarks')
map('n', '<BS>', ':messages<CR>', map_opt 'Show [M]essages')

map('x', '/', '<Esc>/\\%V', { desc = 'Search in visual selection' })
map('i', '<C-D>', '<Del>', map_opt 'Delete character under the cursor')
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
map({ 'n', 'i' }, '<C-space>', function() vim.lsp.buf.signature_help() end, map_opt 'Signature help')

-- === navigation: tag zz at the end
map('n', '<C-u>', '<C-u>zz')
map('n', '<C-d>', '<C-d>zz')
map('n', '<PageUp>', '<C-u>zz')
map('n', '<PageDown>', '<C-d>zz')
map('n', 'n', 'nzzzv')

-- === navigation long wrapped lines
map('n', 'j', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'j']], { expr = true })
map('n', 'k', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'k']], { expr = true })

-- === Enter ===
map('n', '<Enter>', '<cmd>silent! wa<cr>', { desc = 'Save all buffers' })

-- === visual mode
map('v', 'J', ":m '>+1<CR>gv=gv") -- move line down
map('v', 'K', ":m '<-2<CR>gv=gv") -- move line up

-- === visual mode: delete, paste into black hole
map({ 'x', 'v' }, 'p', [["_dP]], map_opt '[P]aste without overwriting the clipboard')
map({ 'v', 'x' }, '<leader>d', [["_x]], map_opt '[D]elete into black hole')

-- === add empty lines
map('n', 'gk', 'O<Esc>j', map_opt 'Insert empty line above')
map('n', 'gj', 'o<Esc>k', map_opt 'Insert empty line below')

-- === window management
map('n', '<C-h>', '<C-w><C-h>', map_opt 'Move focus to the left window')
map('n', '<C-l>', '<C-w><C-l>', map_opt 'Move focus to the right window')
map('n', '<D-j>', '<C-w><C-j>', map_opt 'Move focus to the below window')
map('n', '<D-k>', '<C-w><C-k>', map_opt 'Move focus to the above window')
map('n', '<M-j>', '<C-w><C-j>', map_opt 'Move focus to the below window')
map('n', '<M-k>', '<C-w><C-k>', map_opt 'Move focus to the above window')
