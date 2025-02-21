local map = vim.keymap.set
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

local function yank_function()
  local bufnr = vim.api.nvim_get_current_buf()
  local func_node = Nearest_func_node()
  local func_text = vim.treesitter.get_node_text(func_node, bufnr)
  vim.fn.setreg('*', func_text)
  for child in func_node:iter_children() do
    if child:type() == 'identifier' or child:type() == 'name' then
      local func_name = vim.treesitter.get_node_text(child, bufnr)
      print('Yanked function: ' .. func_name)
      break
    end
  end
end

local function visual_function()
  local func_node = Nearest_func_node()
  local start_row, start_col, end_row, end_col = func_node:range()
  vim.cmd 'normal! v'
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  vim.cmd 'normal! o'
  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
end

local function delete_function()
  visual_function()
  vim.cmd 'normal! d'
end

-- =================== Copilot ===================
local function accept()
  local accept = vim.fn['copilot#Accept']
  assert(accept, 'copilot#Accept not found')
  local res = accept()
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function accept_with_indent()
  local accept = vim.fn['copilot#Accept']
  assert(accept, 'copilot#Accept not found')
  local res = accept()
  res = res .. '\r'
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function accept_word()
  local accept_word = vim.fn['copilot#AcceptWord']
  assert(accept_word, 'copilot#AcceptWord not found')
  local res = accept_word()
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function accept_line()
  local accept_line = vim.fn['copilot#AcceptLine']
  assert(accept_line, 'copilot#AcceptLine not found')
  local res = accept_line()
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function accept_line_with_indent()
  local accept_line = vim.fn['copilot#AcceptLine']
  assert(accept_line, 'copilot#AcceptLine not found')
  local res = accept_line()
  res = res .. '\r'
  vim.api.nvim_feedkeys(res, 'n', false)
end

map('i', '<C-l>', accept_line, { expr = true, silent = true, desc = 'Accept Copilot Line' })
map('i', '<M-y>', accept, { expr = true, silent = true, desc = 'Accept Copilot' })
map('i', '<M-l>', accept_with_indent, { expr = true, silent = true, desc = 'Accept Copilot with newline' })
map('i', '<M-Down>', accept_line_with_indent, { expr = true, silent = true, desc = 'Accept Copilot Line' })
map('i', '<M-f>', accept_word, { expr = true, silent = true, desc = 'Accept Copilot Word' })

-- =================== Extmarks ===================
map('n', '<leader>ce', ':ClearExtmarks<CR>', map_opt '[C]lear [E]xtmarks')
vim.api.nvim_create_user_command('ClearExtmarks', function()
  vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
end, { nargs = 0 })
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

-- =================== LSP diagnostic ===================
map('n', ']g', vim.diagnostic.goto_next, map_opt 'Next diagnostic')
map('n', '[g', vim.diagnostic.goto_prev, map_opt 'Previous diagnostic')

-- ================== LSP Rename the first letter
map('n', '<leader>rc', RenameAndCapitalize, map_opt '[R]ename and [C]apitalize first character')
map('n', '<leader>rl', RenameAndLowercase, map_opt '[R]ename and [L]owercase first character')

-- ================== local leader===================
map('n', '<localleader>w', ':wa<CR>', map_opt '[W]rite all')
map('n', '<localleader>xx', '<cmd>source %<CR>', map_opt '[E]xecute current lua file')
map('n', '<localleader>q', function()
  vim.cmd [[wq]]
  vim.cmd [[qa]]
end, map_opt 'write all and quit all')

-- =================== colorscheme ==================
map('n', '<leader>tcl', ':colorscheme github_light_default<CR>', map_opt '[T]oggle [C]olorscheme [L]ight')
map('n', '<leader>tcr', ':colorscheme rose-pine-moon<CR>', map_opt '[T]oggle [C]olorscheme [R]ose-pine')
map('n', '<leader>tck', ':colorscheme kanagawa-wave<CR>', map_opt '[T]oggle [C]olorscheme [K]anagawa')

-- =================== Navigation ===================
map('i', 'jj', '<Esc>', map_opt 'Exit insert mode with jj')
map('n', '<leader>yf', yank_function, { desc = 'Yank nearest function' })
map('n', '<leader>vf', visual_function, { desc = 'Visual nearest function' })
map('n', '<leader>df', delete_function, { desc = 'Delete nearest function' })

return {}
