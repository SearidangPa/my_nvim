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

local accept_key
if vim.fn.has 'win32' == 1 then
  accept_key = '<M-'
else
  accept_key = '<D-'
end

map('i', '<C-l>', accept_line, { expr = true, silent = true, desc = 'Accept Copilot Line' })
map('i', accept_key .. 'y>', accept, { expr = true, silent = true, desc = 'Accept Copilot' })
map('i', accept_key .. 'l>', accept_line_with_indent, { expr = true, silent = true, desc = 'Accept Copilot with newline' })
map('i', '<M-Down>', accept_line_with_indent, { expr = true, silent = true, desc = 'Accept Copilot Line With newline' })
map('i', '<M-f>', accept_word, { expr = true, silent = true, desc = 'Accept Copilot Word' })

-- =================== Extmarks ===================
map('n', '<leader>ce', ':ClearExtmarks<CR>', map_opt '[C]lear [E]xtmarks')
vim.api.nvim_create_user_command('ClearExtmarks', function()
  vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
end, { nargs = 0 })
-- =================== Window Navigation ===================
vim.api.nvim_create_user_command('Split4060', function()
  local total = vim.o.columns
  local left = math.floor(total * 0.4)
  vim.cmd 'leftabove vsplit'
  vim.cmd 'wincmd h'
  vim.cmd('vertical resize ' .. left)
end, {})
map('n', '<C-h>', '<C-w><C-h>', map_opt 'Move focus to the left window')
map('n', '<C-j>', '<C-w><C-j>', map_opt 'Move focus to the below window')
map('n', '<C-k>', '<C-w><C-k>', map_opt 'Move focus to the above window')
map('n', '<C-l>', '<C-w><C-l>', map_opt 'Move focus to the right window')
-- =================== Terminal ===================
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
-- =================== delete ===================
map('i', '<C-D>', '<Del>', map_opt 'Delete character under the cursor')

-- =================== Insert Empty Lines ===================
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
  vim.cmd [[q]]
end, map_opt '[Q]uit')

-- =================== colorscheme ==================
map('n', '<leader>cl', ':colorscheme github_light_default<CR>', map_opt 'Colorscheme [L]ight')
map('n', '<leader>cr', ':colorscheme rose-pine-moon<CR>', map_opt 'Colorscheme [R]ose-pine')
map('n', '<leader>ck', ':colorscheme kanagawa-wave<CR>', map_opt 'Colorscheme [K]anagawa')

-- =================== Navigation ===================
map('i', 'jj', '<Esc>', map_opt 'Exit insert mode with jj')
map('n', '<leader>yf', yank_function, { desc = 'Yank nearest function' })
map('n', '<leader>vf', visual_function, { desc = 'Visual nearest function' })
map('n', '<leader>df', delete_function, { desc = 'Delete nearest function' })

-- === Remap ===
map('v', 'J', ":m '>+1<CR>gv=gv") -- move line down
map('v', 'K', ":m '<-2<CR>gv=gv") -- move line up
map('n', 'n', 'nzzzv')

map('n', '<C-u>', '<C-u>zz')
map('n', '<C-d>', '<C-d>zz')

map({ 'n', 'v' }, '<leader>y', [["+y]])
map('n', '<localleader>Y', [["pY]])
map('n', '<localleader>p', [["pp]])
map('n', '<localleader>P', [["pP]])

map('x', '<leader>p', [["_dP]], map_opt '[P]aste without overwriting the clipboard')
map('n', '<leader>dd', [["_dd]], map_opt '[D]elete into black hole')

map('n', '<leader>rs', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gc<Left><Left><Left>]])

vim.api.nvim_create_user_command('CopyCurrentFilePath', function()
  vim.fn.setreg('+', vim.fn.expand '%:p')
end, { nargs = 0 })

-- === Quickfix navigation ===
local quickfix = require 'config.quickfix'
map('n', '<leader>qn', ':cnext<CR>zz', { desc = 'Next Quickfix item' })
map('n', '<leader>qp', ':cprevious<CR>zz', { desc = 'Previous Quickfix item' })

-- === Quickfix window controls ===
map('n', '<leader>qc', ':cclose<CR>', { desc = 'Close Quickfix window' })

map('n', '<leader>qo', ':copen<CR>', { desc = 'Open Quickfix window' })
map('n', '<leader>qt', quickfix.toggle_quickfix, { desc = 'toggle diagnostic windows' })
map('n', '<leader>qf', vim.diagnostic.open_float, { desc = 'Open diagnostic [f]loat' })

--- === Quickfix load ===
map('n', '<leader>ql', vim.diagnostic.setqflist, { desc = '[Q]uickfix [L]ist' })
map('n', '<leader>qr', quickfix.lsp_references_nearest_function, { desc = 'Go to func references (excluding test files)' })

--- === Fold ===
map('n', '<Tab>', 'za', { desc = 'Toggle fold' })

--- === Scratch buffer ===
local function new_scratch_buffer()
  vim.cmd 'enew'
  vim.cmd 'setlocal buftype=nofile bufhidden=hide noswapfile'
end
vim.api.nvim_create_user_command('NewBuf', new_scratch_buffer, { desc = 'Start a scratch buffer' })

--- === logging ===
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  callback = function()
    vim.keymap.set('n', '<leader>ll', 'olog.Printf("=====> %v\\n", ', {
      buffer = true,
      desc = 'Insert logging line',
    })
  end,
})

vim.keymap.set('n', '<localleader>m', ':messages<CR>', map_opt 'Show [M]essages')

vim.keymap.set('n', '<leader>ng', function()
  require('neogen').generate()
end, map_opt '[N]eogen [G]enerate')
return {}
