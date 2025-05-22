local set_map_key = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end
set_map_key('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

local function save_all()
  if vim.bo.filetype == 'snacks_input' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Enter>', true, false, true), 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
  end
  vim.cmd 'silent! wa'
end
set_map_key('n', '<Enter>', save_all, { desc = 'Save all buffers' })

set_map_key('n', '<Tab>', 'zA', map_opt 'Toggle fold')
set_map_key('n', ']]', 'zj', map_opt 'Next fold')
set_map_key('n', '[[', 'zk', map_opt 'Previous fold')

set_map_key('n', '<leader>ce', ':ClearExtmarks<CR>', map_opt '[C]lear [E]xtmarks')
set_map_key('n', '<BS>', ':messages<CR>', map_opt 'Show [M]essages')
set_map_key('x', '/', '<Esc>/\\%V', { desc = 'Search in visual selection' })

-- === Insert mode
set_map_key('i', '<C-D>', '<Del>', map_opt 'Delete character under the cursor')
set_map_key({ 'n', 'i' }, '<C-space>', function() vim.lsp.buf.signature_help() end, map_opt 'Signature help')

-- === navigation: tag zz at the end
set_map_key('n', '<C-u>', '<C-u>zz')
set_map_key('n', '<C-d>', '<C-d>zz')
set_map_key('n', '<PageUp>', '<C-u>zz')
set_map_key('n', '<PageDown>', '<C-d>zz')
set_map_key('n', 'n', 'nzzzv')

-- === navigation long wrapped lines
set_map_key('n', 'j', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'j']], { expr = true })
set_map_key('n', 'k', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'k']], { expr = true })

-- === visual mode
set_map_key('v', 'J', ":m '>+1<CR>gv=gv") -- move line down
set_map_key('v', 'K', ":m '<-2<CR>gv=gv") -- move line up

-- === visual mode: delete, paste into black hole
set_map_key({ 'x', 'v' }, 'p', [["_dP]], map_opt '[P]aste without overwriting the clipboard')
set_map_key({ 'v', 'x' }, '<leader>d', [["_x]], map_opt '[D]elete into black hole')

-- === window management
set_map_key('n', '<C-h>', '<C-w><C-h>', map_opt 'Move focus to the left window')
set_map_key('n', '<C-l>', '<C-w><C-l>', map_opt 'Move focus to the right window')
set_map_key('n', '<D-j>', '<C-w><C-j>', map_opt 'Move focus to the below window')
set_map_key('n', '<D-k>', '<C-w><C-k>', map_opt 'Move focus to the above window')
set_map_key('n', '<M-j>', '<C-w><C-j>', map_opt 'Move focus to the below window')
set_map_key('n', '<M-k>', '<C-w><C-k>', map_opt 'Move focus to the above window')
