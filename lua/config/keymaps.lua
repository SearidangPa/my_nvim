local function toggle_quickfix()
  if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix == 1 then
    vim.cmd 'cclose'
  else
    vim.cmd 'copen'
  end
end
local map = vim.keymap.set

local function map_opt(desc)
  return { noremap = true, silent = true, desc = desc }
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

-- =================== Insert Empty line ===================
vim.api.nvim_set_keymap('n', 'gk', 'O<Esc>j', map_opt 'Insert empty line above')
vim.api.nvim_set_keymap('n', 'gj', 'o<Esc>k', map_opt 'Insert empty line below')
vim.keymap.set('i', '<M-(>', '()<left>', { noremap = true, silent = true, desc = 'Insert ()' })

-- =================== Esc Insert Mode ===================
map('i', 'jj', '<Esc>', map_opt 'Exit insert mode with jj')

-- -- =================== Quickfix ===================
map('n', '<leader>ql', function()
  vim.diagnostic.setqflist()
end, { desc = '[Q]uickfix [L]ist' })
map('n', '<leader>qn', ':cnext<CR>', { desc = 'Next Quickfix item' })
map('n', '<leader>qp', ':cprevious<CR>', { desc = 'Previous Quickfix item' })
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

map('i', '<C-j>', function()
  local accept = vim.fn['copilot#Accept']
  local res = accept(vim.api.nvim_replace_termcodes('<Tab>', true, true, false))
  res = res .. '\n'
  vim.api.nvim_feedkeys(res, 'n', false)
end, { expr = true, remap = false, desc = 'Copilot Accept and go down' })

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

vim.api.nvim_create_user_command('RenameCapitalize', function()
  RenameAndCapitalize()
end, {})

vim.api.nvim_create_user_command('RenameLowercase', function()
  RenameAndLowercase()
end, {})

vim.keymap.set('n', '<leader>ts', function()
  require('spectre').toggle()
end, { noremap = true, silent = true, desc = '[T]oggle [S]pectre' })

vim.keymap.set('n', '<leader>rc', ':RenameCapitalize<CR>', map_opt '[R]ename and [c]apitalize first character')
vim.keymap.set('n', '<leader>rl', ':RenameLowercase<CR>', map_opt '[R]ename and [l]owercase first character')

-- ================== local leader===================
vim.keymap.set('n', '<localleader>w', ':wa<CR>', { noremap = false, desc = '[W]rite all' })
vim.keymap.set('n', '<localleader>xx', '<cmd>source % CR>', map_opt 'Source the current lua file')

-- =================== theme ==================
vim.keymap.set('n', '<leader>tcl', ':colorscheme github_light_default<CR>', map_opt '[T]oggle [C]olorscheme [L]ight')
vim.keymap.set('n', '<leader>tcd', ':colorscheme kanagawa-wave<CR>', map_opt '[T]oggle [C]olorscheme [D]ark')

return {}
