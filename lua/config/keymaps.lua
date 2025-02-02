local map = vim.keymap.set

local function buf_clear_name_space()
  vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
end

local function toggle_quickfix()
  if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix == 1 then
    vim.cmd 'cclose'
  else
    vim.cmd 'copen'
  end
end

local function map_opt(desc)
  return { noremap = true, silent = true, desc = desc }
end

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

local function accept_with_insert_line()
  local accept = vim.fn['copilot#Accept']
  local res = accept(vim.api.nvim_replace_termcodes('<Tab>', true, true, false))
  res = res .. '\n'
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function accept_word()
  local accept = vim.fn['copilot#AcceptWord']
  local res = accept(vim.api.nvim_replace_termcodes('<M-Right>', true, true, false))
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function accept_line()
  local accept = vim.fn['copilot#AcceptLine']
  local res = accept(vim.api.nvim_replace_termcodes('<Tab>', true, true, false))
  vim.api.nvim_feedkeys(res, 'n', false)
end

-- =================== Window Navigation ===================
map('n', '<C-h>', '<C-w><C-h>', map_opt 'Move focus to the left window')
map('n', '<C-l>', '<C-w><C-l>', map_opt 'Move focus to the right window')
map('n', '<C-j>', '<C-w><C-j>', map_opt 'Move focus to the lower window')
map('n', '<C-k>', '<C-w><C-k>', map_opt 'Move focus to the upper window')

-- =================== Terminal ===================
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- =================== delete ===================
map('i', '<C-D>', '<Del>', map_opt 'Delete character under the cursor')

-- =================== Insert Assistance ===================
map('n', 'gk', 'O<Esc>j', map_opt 'Insert empty line above')
map('n', 'gj', 'o<Esc>k', map_opt 'Insert empty line below')
map('i', '<M-(>', '()<left>', { noremap = true, silent = true, desc = 'Insert ()' })

-- =================== Quickfix ===================
map('n', '<leader>ql', vim.diagnostic.setqflist, { desc = '[Q]uickfix [L]ist' })
map('n', '<leader>qn', ':cnext<CR>', { desc = 'Next Quickfix item' })
map('n', '<leader>qp', ':cprevious<CR>', { desc = 'Previous Quickfix item' })
map('n', '<leader>qc', ':cclose<CR>', { desc = 'Close Quickfix window' })
map('n', '<leader>qo', ':copen<CR>', { desc = 'Open Quickfix window' })
map('n', '<leader>qt', toggle_quickfix, { desc = 'toggle diagnostic windows' })
map('n', '<leader>qf', vim.diagnostic.open_float, { desc = 'Open diagnostic [f]loat' })
map('n', '<leader>qr', vim.diagnostic.reset, { desc = 'diagnostics [r]eset' })

-- =================== LSP diagnostic ===================
map('n', ']g', vim.diagnostic.goto_next, map_opt 'Next diagnostic')
map('n', '[g', vim.diagnostic.goto_prev, map_opt 'Previous diagnostic')

-- ================== Copilot ===================

map('i', '<C-l>', accept_line, { expr = true, remap = false, desc = 'Copilot Accept [l]ine' })
map('i', '<M-f>', accept_word, { expr = true, remap = false, desc = 'Copilot Accept Word' })
map('i', '<M-y>', accept_with_insert_line, { expr = true, remap = false, desc = 'Copilot Accept and go down' })

-- ================== LSP Rename the first letter
map('n', '<leader>rc', RenameAndCapitalize, map_opt '[R]ename and [C]apitalize first character')
map('n', '<leader>rl', RenameAndLowercase, map_opt '[R]ename and [L]owercase first character')

-- ================== local leader===================
map('n', '<localleader>w', ':wa<CR>', map_opt '[W]rite all')
map('n', '<localleader>xx', '<cmd>source %<CR>', map_opt '[E]xecute current lua file')

-- =================== colorscheme ==================
map('n', '<leader>tcl', ':colorscheme github_light_default<CR>', map_opt '[T]oggle [C]olorscheme [L]ight')
map('n', '<leader>tcr', ':colorscheme rose-pine-moon<CR>', map_opt '[T]oggle [C]olorscheme [R]ose-pine')
map('n', '<leader>tck', ':colorscheme kanagawa-wave<CR>', map_opt '[T]oggle [C]olorscheme [K]anagawa')

-- =================== Navigation ===================
map('i', 'jj', '<Esc>', map_opt 'Exit insert mode with jj')
map('i', '<C-e>', '<End>', map_opt 'Move to the end of the line')
map('i', '<C-a>', '<Esc>I', map_opt 'Move to the beginning of the line')

-- Treewalker movement
map({ 'n', 'v' }, '<M-k>', '<cmd>Treewalker Up<cr>', { silent = true })
map({ 'n', 'v' }, '<M-j>', '<cmd>Treewalker Down<cr>', { silent = true })
map({ 'n', 'v' }, '<M-h>', '<cmd>Treewalker Left<cr>', { silent = true })
map({ 'n', 'v' }, '<M-l>', '<cmd>Treewalker Right<cr>', { silent = true })

-- Treewalker swapping
map('n', '<M-S-k>', '<cmd>Treewalker SwapUp<cr>', { silent = true })
map('n', '<M-S-j>', '<cmd>Treewalker SwapDown<cr>', { silent = true })
map('n', '<M-S-h>', '<cmd>Treewalker SwapLeft<cr>', { silent = true })
map('n', '<M-S-l>', '<cmd>Treewalker SwapRight<cr>', { silent = true })

-- clear all extmarks
map('n', '<leader>ce', buf_clear_name_space, map_opt '[C]lear [E]xtmarks')

-- blackboard
local bb = require 'config.blackboard'
vim.keymap.set('n', '<leader>tm', bb.toggle_mark_window, { desc = '[T]oggle [M]ark list window' })
vim.keymap.set('n', '<leader>mc', bb.toggle_mark_context, { desc = '[M]ark [C]ontext' })

return {}
