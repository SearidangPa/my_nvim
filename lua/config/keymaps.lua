local function SuggestLines(n)
  vim.fn['copilot#Accept'] ''
  local queuedText = vim.fn['copilot#TextQueuedForInsertion']() or ''
  queuedText = queuedText:match '^%s*(.-)%s*$' or ''
  local lines = {}
  for line in queuedText:gmatch '[^\n]+' do
    table.insert(lines, line)
  end
  local selectedLines = vim.list_slice(lines, 1, n or #lines)
  for i, line in ipairs(selectedLines) do
    selectedLines[i] = line:match '^%s*(.-)$' -- Trim leading spaces/tabs
  end
  return table.concat(selectedLines, '\n') .. '\n'
end

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
map('n', '[t', ':tabprev<CR>', map_opt 'Previous tab')
map('n', ']t', ':tabnext<CR>', map_opt 'Next tab')

-- =================== diagnostics ===================
map('n', ']g', vim.diagnostic.goto_next, map_opt 'Next diagnostic')
map('n', '[g', vim.diagnostic.goto_prev, map_opt 'Previous diagnostic')

-- =================== delete ===================
map('i', '<C-D>', '<Del>', map_opt 'Delete character under the cursor')

-- =================== Insert Empty line ===================
vim.api.nvim_set_keymap('n', 'gk', 'O<Esc>j', map_opt 'Insert empty line above')
vim.api.nvim_set_keymap('n', 'gj', 'o<Esc>k', map_opt 'Insert empty line below')

-- =================== Esc Insert Mode ===================
map('i', 'jj', '<Esc>', map_opt 'Exit insert mode with jj')

map('n', '<leader>qs', function()
  vim.diagnostic.setqflist()
  vim.cmd 'copen'
end, { desc = 'Fill the Quickfix list with diagnostics' })

map('n', '<leader>ql', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
map('n', '<leader>qn', ':cnext<CR>', { desc = 'Next Quickfix item' })
map('n', '<leader>qp', ':cprevious<CR>', { desc = 'Previous Quickfix item' })
map('n', '<leader>qc', ':cclose<CR>', { desc = 'Close Quickfix window' })
map('n', '<leader>qo', ':copen<CR>', { desc = 'Open Quickfix window' })
map('n', '<leader>qt', toggle_quickfix, { desc = 'toggle diagnostic windows' })

map('n', '<leader>qr', function()
  vim.diagnostic.reset()
end, { desc = 'diagnostics reset' })

map('n', '<leader>qf', function()
  vim.diagnostic.open_float()
end, { desc = 'Open diagnostic float' })

--[[
      ================== Copilot ===================
--]]

map('i', '<M-f>', function()
  return vim.fn['copilot#AcceptWord'] ''
end, { expr = true, remap = false })

for i = 1, 9 do
  local key = string.format('<M-%d>', i)
  map('i', key, function()
    return SuggestLines(i)
  end, { expr = true, remap = false })
end

function RenameAndCapitalize()
  local current_word = vim.fn.expand '<cword>'
  local capitalized_word = current_word:sub(1, 1):upper() .. current_word:sub(2)
  vim.lsp.buf.rename(capitalized_word)
end

vim.api.nvim_create_user_command('RenameCapitalize', function()
  RenameAndCapitalize()
end, {})

vim.keymap.set('n', '<leader>rc', ':RenameCapitalize<CR>', map_opt 'Rename and capitalize first character')

return {}
