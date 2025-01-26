local function toggle_quickfix()
  if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix == 1 then
    vim.cmd 'cclose'
  else
    vim.cmd 'copen'
  end
end
local map = vim.keymap.set

local function map_opt(desc)
  return { noremap = true, silent = false, desc = desc }
end

-- =================== Window Navigation ===================
map('n', '<C-h>', '<C-w><C-h>', map_opt 'Move focus to the left window')
map('n', '<C-l>', '<C-w><C-l>', map_opt 'Move focus to the right window')
map('n', '<C-j>', '<C-w><C-j>', map_opt 'Move focus to the lower window')
map('n', '<C-k>', '<C-w><C-k>', map_opt 'Move focus to the upper window')

-- =================== Terminal ===================
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- =================== Tabs ===================
map('n', '[t', ':tabprev<CR>', map_opt 'Previous [t]ab')
map('n', ']t', ':tabnext<CR>', map_opt 'Next [t]ab')

-- =================== delete ===================
map('i', '<C-D>', '<Del>', map_opt 'Delete character under the cursor')

-- =================== Insert Assistance ===================
vim.api.nvim_set_keymap('n', 'gk', 'O<Esc>j', map_opt 'Insert empty line above')
vim.api.nvim_set_keymap('n', 'gj', 'o<Esc>k', map_opt 'Insert empty line below')
vim.keymap.set('i', '<M-(>', '()<left>', { noremap = true, silent = true, desc = 'Insert ()' })

-- -- =================== Quickfix ===================
map('n', '<leader>ql', function()
  vim.diagnostic.setqflist()
end, { desc = '[Q]uickfix [L]ist' })
map('n', ']q', ':cnext<CR>', { desc = 'Next Quickfix item' })
map('n', '[q', ':cprevious<CR>', { desc = 'Previous Quickfix item' })
map('n', '<leader>qc', ':cclose<CR>', { desc = 'Close Quickfix window' })
map('n', '<leader>qo', ':copen<CR>', { desc = 'Open Quickfix window' })
map('n', '<leader>qt', toggle_quickfix, { desc = 'toggle diagnostic windows' })

-- =================== LSP diagnostic ===================
map('n', ']g', vim.diagnostic.goto_next, map_opt 'Next diagnostic')
map('n', '[g', vim.diagnostic.goto_prev, map_opt 'Previous diagnostic')

map('n', '<leader>qr', function()
  vim.diagnostic.reset()
end, { desc = 'diagnostics [r]eset' })

map('n', '<leader>qf', function()
  vim.diagnostic.open_float()
end, { desc = 'Open diagnostic [f]loat' })

--[[
      ================== Copilot ===================
--]]

map('i', '<C-l>', function()
  local accept = vim.fn['copilot#AcceptLine']
  local res = accept(vim.api.nvim_replace_termcodes('<Tab>', true, true, false))
  vim.api.nvim_feedkeys(res, 'n', false)
end, { expr = true, remap = false, desc = 'Copilot Accept [l]ine' })

map('i', '<M-y>', function()
  local accept = vim.fn['copilot#Accept']
  local res = accept(vim.api.nvim_replace_termcodes('<Tab>', true, true, false))
  res = res .. '\n'
  vim.api.nvim_feedkeys(res, 'n', false)
end, { expr = true, remap = false, desc = 'Copilot Accept and go down' })

map('i', '<M-f>', function()
  local accept = vim.fn['copilot#AcceptWord']
  local res = accept(vim.api.nvim_replace_termcodes('<M-Right>', true, true, false))
  vim.api.nvim_feedkeys(res, 'n', false)
end, { expr = true, remap = false, desc = 'Copilot Accept Word' })

map('i', '<Tab>', function()
  local accept = vim.fn['copilot#Accept']
  local res = accept(vim.api.nvim_replace_termcodes('<Tab>', true, true, false))
  if res == '<Tab>' or res == '' then
    return '\t'
  end
  vim.api.nvim_feedkeys(res, 'n', true)
  return ''
end, { expr = true, remap = false, desc = 'Copilot Accept', silent = true })

-- [[
-- ================== Rename the first letter
-- ]]

function RenameAndCapitalize()
  local current_word = vim.fn.expand '<cword>'
  local capitalized_word = current_word:sub(1, 1):upper() .. current_word:sub(2)
  vim.lsp.buf.rename(capitalized_word)
end

function RenameAndLowercase()
  local current_word = vim.fn.expand '<cword>'
  local lowercase_word = current_word:sub(1, 1):lower() .. current_word:sub(2)
  vim.lsp.buf.rename(lowercase_word)
end

vim.keymap.set('n', '<leader>rc', function()
  RenameAndCapitalize()
end, map_opt '[R]ename and [C]apitalize first character')

vim.keymap.set('n', '<leader>rl', function()
  RenameAndLowercase()
end, map_opt '[R]ename and [L]owercase first character')

-- ================== local leader===================
vim.keymap.set('n', '<localleader>w', ':wa<CR>', map_opt '[W]rite all')
vim.keymap.set('n', '<localleader>xx', '<cmd>source %<CR>', map_opt '[E]xecute current lua file')

-- =================== theme ==================
vim.keymap.set('n', '<leader>tcl', ':colorscheme github_light_default<CR>', map_opt '[T]oggle [C]olorscheme [L]ight')
vim.keymap.set('n', '<leader>tcd', ':colorscheme kanagawa-wave<CR>', map_opt '[T]oggle [C]olorscheme [D]ark')

-- =================== fold ===================
vim.keymap.set('n', '<leader>z', function()
  vim.cmd 'normal! vaBzf'
end, map_opt 'Fold current paragraph')

vim.keymap.set('n', '<Tab>', 'za', map_opt 'Toggle fold')

-- =================== Navigation ===================
vim.keymap.set('i', 'jj', '<Esc>', map_opt 'Exit insert mode with jj')

-- Treewalker movement
vim.keymap.set({ 'n', 'v' }, '<M-k>', '<cmd>Treewalker Up<cr>', { silent = true })
vim.keymap.set({ 'n', 'v' }, '<M-j>', '<cmd>Treewalker Down<cr>', { silent = true })
vim.keymap.set({ 'n', 'v' }, '<M-h>', '<cmd>Treewalker Left<cr>', { silent = true })
vim.keymap.set({ 'n', 'v' }, '<M-l>', '<cmd>Treewalker Right<cr>', { silent = true })

-- Treewalker swapping
vim.keymap.set('n', '<M-S-k>', '<cmd>Treewalker SwapUp<cr>', { silent = true })
vim.keymap.set('n', '<M-S-j>', '<cmd>Treewalker SwapDown<cr>', { silent = true })
vim.keymap.set('n', '<M-S-h>', '<cmd>Treewalker SwapLeft<cr>', { silent = true })
vim.keymap.set('n', '<M-S-l>', '<cmd>Treewalker SwapRight<cr>', { silent = true })

-- clear all extmarks
vim.keymap.set('n', '<leader>ce', function()
  vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
end, { silent = true, desc = '[C]lear [E]xtmarks' })

local sl = require 'luasnip.extras.snippet_list'
local function snip_info(snippet)
  return { name = snippet.name }
end
vim.keymap.set('n', '<leader>ls', function()
  sl.open { snip_info = snip_info }
end, { silent = true, desc = '[L]ist [S]nippets' })

return {}
