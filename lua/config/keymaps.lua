local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

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
  local util_find_func = require 'config.util_find_func'
  local func_node = util_find_func.nearest_func_node()
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

--- === Powerful Esc. Copied from Maria SolOs ===
vim.keymap.set({ 'i', 's', 'n' }, '<esc>', function()
  if require('luasnip').expand_or_jumpable() then
    require('luasnip').unlink_current()
  end
  return '<esc>'
end, { desc = 'Escape, clear hlsearch, and stop snippet session', expr = true })

vim.keymap.set('n', 'j', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'j']], { expr = true })
vim.keymap.set('n', 'k', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'k']], { expr = true })

-- Make U opposite to u.
vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })

-- =================== Extmarks ===================
vim.api.nvim_create_user_command('ClearExtmarks', function() vim.api.nvim_buf_clear_namespace(0, -1, 0, -1) end, { nargs = 0 })
map('n', '<leader>ce', ':ClearExtmarks<CR>', map_opt '[C]lear [E]xtmarks')
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
map('n', ']g', function() vim.diagnostic.jump { count = 1, float = true } end, map_opt 'Next diagnostic')
map('n', '[g', function() vim.diagnostic.jump { count = -1, float = true } end, map_opt 'Previous diagnostic')

map({ 'n', 'i' }, '<C-space>', function() vim.lsp.buf.signature_help() end, map_opt 'Signature help')

-- ================== LSP Rename the first letter
map('n', '<leader>rc', RenameAndCapitalize, map_opt '[R]ename and [C]apitalize first character')
map('n', '<leader>rl', RenameAndLowercase, map_opt '[R]ename and [L]owercase first character')

-- ================== local leader===================
map('n', '<localleader>w', function() vim.cmd [[:wa]] end, map_opt '[W]rite all')

map({ 'v', 'x' }, '<localleader>d', [["_x]], map_opt '[D]elete into black hole')
map('n', '<localleader>xx', '<cmd>source %<CR>', map_opt '[E]xecute current lua file')
map('n', '<localleader>q', function() vim.cmd [[q]] end, map_opt '[Q]uit')

-- =================== colorscheme ==================
map('n', '<leader>cl', ':colorscheme github_light_default<CR>', map_opt 'Colorscheme [L]ight')
map('n', '<leader>cr', ':colorscheme rose-pine-moon<CR>', map_opt 'Colorscheme [R]ose-pine')
map('n', '<leader>ck', ':colorscheme kanagawa-wave<CR>', map_opt 'Colorscheme [K]anagawa')

-- =================== Navigation ===================
map('i', '<Insert>', '<Esc>', map_opt 'Exit insert mode with jj')

-- === Visual select ===
map('n', '<leader>va', function() vim.cmd 'normal! ggVG' end, { desc = 'Yank all lines' })
map('x', '/', '<Esc>/\\%V', { noremap = true })

-- === Yank ===
map('n', '<leader>yf', yank_function, { desc = 'Yank nearest function' })

map('n', '<leader>ya', function()
  local cur_pos = vim.fn.getpos '.'
  vim.cmd 'normal! ggyG'
  vim.fn.setpos('.', cur_pos)
end, { desc = 'Yank all lines' })

-- === Remap ===
map('v', 'J', ":m '>+1<CR>gv=gv") -- move line down
map('v', 'K', ":m '<-2<CR>gv=gv") -- move line up
map('n', 'n', 'nzzzv')

map('n', '<C-u>', '<C-u>zz')
map('n', '<C-d>', '<C-d>zz')

map('x', '<leader>p', [["_dP]], map_opt '[P]aste without overwriting the clipboard')

map('n', '<leader>rs', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/g<Left><Left>]])

vim.api.nvim_create_user_command('CopyCurrentFilePath', function() vim.fn.setreg('+', vim.fn.expand '%:p') end, { nargs = 0 })

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

-- Function to convert visually selected // comments to /* */ block comment
local function convert_line_comments_to_block()
  vim.cmd [[normal! d]]
  local clipboard_content = vim.trim(vim.fn.getreg '+') -- use the '+' register on Windows
  local lines = vim.split(clipboard_content, '\r?\n') -- split on CRLF or LF

  local processed_lines = {}
  for _, line in ipairs(lines) do
    local processed = line:gsub('^%s*// ?', '')
    table.insert(processed_lines, processed)
  end

  local result = { '/*' }
  for _, line in ipairs(processed_lines) do
    table.insert(result, line)
  end
  table.insert(result, '*/\n')

  vim.fn.setreg('+', table.concat(result, '\n')) -- set the modified content to the '+' register
  vim.cmd [[normal! P]]
end

vim.keymap.set({ 'v', 'c' }, '<localleader>8', convert_line_comments_to_block, map_opt 'Convert line comments to block comment')
vim.keymap.set('n', '<localleader>m', ':messages<CR>', map_opt 'Show [M]essages')

vim.keymap.set('n', '<leader>nf', function() require('neogen').generate() end, map_opt '[N]eogen [F]unction')
vim.keymap.set('n', '<laader>gd', ':CopilotChatDoc<CR>', map_opt '[G]enerate [D]ocumentation')

--- === Yank inside fenced_code_block ===
--- Very useful for copying code from copilot chat
local function find_code_block(node, row, col)
  assert(node, 'Node cannot be nil')

  if node:type() == 'fenced_code_block' then
    local start_row, _, end_row, _ = node:range()
    if row >= start_row and row <= end_row then
      return node
    end
  end

  -- Search through children recursively
  for child in node:iter_children() do
    local result = find_code_block(child, row, col)
    if result then
      return result
    end
  end

  return nil
end

local function yank_fenced_code_block()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1] - 1 -- Convert to 0-indexed
  local col = cursor_pos[2]
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  assert(lang, 'markdown', 'This command only works in markdown files')
  local parser = vim.treesitter.get_parser(bufnr, lang)
  assert(parser, 'No parser found for this buffer')
  local root = parser:parse()[1]:root()
  local code_block = find_code_block(root, row, col)
  assert(code_block, 'No code block found at cursor position')

  local content_node = nil
  for child in code_block:iter_children() do
    if child:type() == 'code_fence_content' then
      content_node = child
      break
    end
  end
  assert(content_node, 'Could not find code content in block')
  local start_row, start_col, end_row, end_col = content_node:range()
  start_row = start_row + 1
  end_row = end_row
  vim.cmd(start_row .. ',' .. end_row .. 'yank')
  make_notify('Yanked code block content from line ' .. start_row .. ' to ' .. end_row, vim.log.levels.INFO)
end

vim.api.nvim_create_user_command('YankCodeBlock', yank_fenced_code_block, {
  desc = 'Yank content inside fenced code blocks using Tree-sitter',
})
vim.keymap.set('n', '<localleader>y', ':YankCodeBlock<CR>', { noremap = true, silent = true, desc = 'Yank code block content' })

vim.keymap.set('v', '<localleader>r', function()
  vim.cmd 'normal! y'
  local selected_text = vim.fn.escape(vim.fn.getreg '"', '/\\')
  selected_text = vim.trim(selected_text)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(':%s/' .. selected_text .. '//gc<Left><Left><Left>', true, true, true), 'n', false)
end, { desc = 'Substitute the visual selection' })

--- === New Scratch Buffer ===
local new_scratch_buf = function()
  vim.cmd 'enew'
  vim.cmd 'setlocal buftype=nofile bufhidden=hide noswapfile'
  vim.cmd 'setlocal filetype=markdown'
end
vim.api.nvim_create_user_command('NewScratch', new_scratch_buf, { desc = 'Start a scratch buffer' })

return {}
