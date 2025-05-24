local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end
map('n', ']g', function() vim.diagnostic.jump { count = 1, float = true } end, map_opt 'Next diagnostic')
map('n', '[g', function() vim.diagnostic.jump { count = -1, float = true } end, map_opt 'Previous diagnostic')
-- === Quickfix navigation ===
map('n', ']q', ':cnext<CR>zz', { desc = 'Next Quickfix item' })
map('n', '[q', ':cprevious<CR>zz', { desc = 'Previous Quickfix item' })

-- === Quickfix window controls ===
map('n', '<leader>qc', ':cclose<CR>', { desc = 'Close Quickfix window' })
map('n', '<leader>qo', ':copen<CR>', { desc = 'Open Quickfix window' })
map('n', '<leader>x', vim.diagnostic.open_float, { desc = 'Diagnostic float' })

--- === Quickfix load ===
map('n', '<leader>ql', vim.diagnostic.setqflist, { desc = '[Q]uickfix [L]ist' })

map('n', '<leader>qf', require('custom.quickfix_func_ref_decl').load_definitions_to_refactor, map_opt '[Q]uickfix function declarations [R]eference ')
map('n', '<leader>qr', require('custom.quickfix_func_ref_decl').load_all_function_references, map_opt '[Q]uickfix function declarations [R]eference ')
