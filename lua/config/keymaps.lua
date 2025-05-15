local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

vim.keymap.set(
  { 'v', 'n' },
  '<localleader>av',
  function() require('codecompanion').prompt 'docfn' end,
  { noremap = true, silent = true, desc = '[A]dd doc to a visual selected block' }
)

vim.keymap.set({ 'v', 'n' }, '<localleader>ad', function()
  local util_find_func = require 'config.util_find_func'
  util_find_func.visual_function()
  vim.cmd [[normal! o]]
  require('codecompanion').prompt 'docfn'
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
end, { noremap = true, silent = true, desc = '[A]dd [D]oc to a function' })

vim.keymap.set('i', '<M-s>', function() require('hopcopilot').hop_copilot() end, { expr = true, silent = true, desc = 'hop copilot' })
vim.keymap.set('i', '<D-s>', function() require('hopcopilot').hop_copilot() end, { expr = true, silent = true, desc = 'hop copilot' })

local function accept(opts)
  opts = opts or {}
  local no_indentation = opts.no_indentation or false
  local only_one_line = opts.only_one_line or false
  local accept_fn
  if only_one_line then
    accept_fn = vim.fn['copilot#AcceptLine']
  else
    accept_fn = vim.fn['copilot#Accept']
  end
  assert(accept_fn, 'copilot accept or accept line not found')
  local res = accept_fn()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local next_line = cursor_pos[1]
  local next_line_content = vim.api.nvim_buf_get_lines(0, next_line, next_line + 1, false)
  local is_next_line_empty = next_line_content[1] and next_line_content[1]:match '^%s*$'
  if is_next_line_empty and not no_indentation then
    res = res .. '\n'
  end
  vim.api.nvim_feedkeys(res, 'n', false)
end

-- ctrl-l does not work on windows terminal for some reason
map('i', '<C-l>', function() accept { no_indentation = true, only_one_line = true } end, { expr = true, silent = true, desc = 'Accept Copilot' })
map('i', '<D-y>', accept, { expr = true, silent = true, desc = 'Accept Copilot' })
map('i', '<M-y>', accept, { expr = true, silent = true, desc = 'Accept Copilot' })

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

vim.keymap.set('n', '<C-S-h>', '<cmd>Treewalker SwapLeft<cr>', { silent = true })
vim.keymap.set('n', '<C-S-l>', '<cmd>Treewalker SwapRight<cr>', { silent = true })

vim.keymap.set('n', 'yc', function() vim.cmd [[norm y2t:]] end, { silent = true })

vim.keymap.set({ 'n', 'x' }, '<leader>gy', function()
  ---@diagnostic disable-next-line: missing-fields
  Snacks.gitbrowse { open = function(url) vim.fn.setreg('+', url) end, notify = false }
end, { desc = 'Git Browse (copy)' })

vim.keymap.set({ 'i', 'v' }, '<Insert>', '<ESC>', { desc = 'Escape Insert mode' })

vim.keymap.set('n', '<leader>ut', function() require('theme-loader').toggle_os_theme() end, { desc = '[U]i [T]heme' })

vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
vim.keymap.set(
  'n',
  '<leader>sb',
  function() require('fzf-lua').git_branches {} end,
  { noremap = true, silent = true, desc = '[S]earch remote and local [B]ranches' }
)

vim.keymap.set({ 'i', 's', 'n' }, '<esc>', function()
  if require('luasnip').expand_or_jumpable() then
    require('luasnip').unlink_current()
  end
  return '<esc>'
end, { desc = 'Escape, clear hlsearch, and stop snippet session', expr = true })

vim.keymap.set('n', 'j', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'j']], { expr = true })
vim.keymap.set('n', 'k', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'k']], { expr = true })

vim.api.nvim_create_user_command('ClearExtmarks', function() vim.api.nvim_buf_clear_namespace(0, -1, 0, -1) end, { nargs = 0 })

vim.api.nvim_create_user_command('Split4060', function()
  local total = vim.o.columns
  local left = math.floor(total * 0.4)
  vim.cmd 'leftabove vsplit'
  vim.cmd 'wincmd h'
  vim.cmd('vertical resize ' .. left)
end, {})

map('n', '<C-h>', '<C-w><C-h>', map_opt 'Move focus to the left window')
map('n', '<C-l>', '<C-w><C-l>', map_opt 'Move focus to the right window')
map('n', '<D-j>', '<C-w><C-j>', map_opt 'Move focus to the below window')
map('n', '<D-k>', '<C-w><C-k>', map_opt 'Move focus to the above window')
map('n', '<M-j>', '<C-w><C-j>', map_opt 'Move focus to the below window')
map('n', '<M-k>', '<C-w><C-k>', map_opt 'Move focus to the above window')

map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' }) -- exit terminal mode
map('i', '<C-D>', '<Del>', map_opt 'Delete character under the cursor')
map('n', 'gk', 'O<Esc>j', map_opt 'Insert empty line above')
map('n', 'gj', 'o<Esc>k', map_opt 'Insert empty line below')

map({ 'n', 'i' }, '<C-space>', function() vim.lsp.buf.signature_help() end, map_opt 'Signature help')

-- ================== LSP Rename the first letter
map('n', '<localleader>rc', RenameAndCapitalize, map_opt '[R]ename and [C]apitalize first character')
map('n', '<localleader>rl', RenameAndLowercase, map_opt '[R]ename and [L]owercase first character')

map('n', '<Enter>', function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(':wa<CR>', true, false, true), 'n', false) end, map_opt '[W]rite all') -- yolo :D

map('n', '<S-Enter>', function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Enter>', true, false, true), 'n', false)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
end, map_opt 'remap Enter') -- yolo :D

map('n', '<leader><BS>', ':ClearExtmarks<CR>', map_opt '[C]lear [E]xtmarks')

map({ 'v', 'x' }, '<leader>d', [["_x]], map_opt '[D]elete into black hole')

-- === Visual select ===
map('n', '<leader>va', function() vim.cmd 'normal! ggVG' end, { desc = '[V]isual [A]ll' })
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
map('n', '<PageUp>', '<C-u>zz')
map('n', '<PageDown>', '<C-d>zz')

map('x', '<leader>p', [["_dP]], map_opt '[P]aste without overwriting the clipboard')

map('n', '<localleader>rs', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/g<Left><Left>]])

vim.api.nvim_create_user_command('CopyCurrentFilePath', function() vim.fn.setreg('+', vim.fn.expand '%:p') end, { nargs = 0 })

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

vim.keymap.set(
  'n',
  '<leader>qr',
  function() require('custom.quickfix_func_ref_decl').load_func_refs() end,
  { desc = '[L]oad function [R]eferences', noremap = true, silent = true }
)

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

vim.keymap.set({ 'v', 'c' }, '<leader>8', convert_line_comments_to_block, map_opt 'Convert line comments to block comment')
vim.keymap.set('n', '<BS>', ':messages<CR>', map_opt 'Show [M]essages')

vim.keymap.set('v', '<leader>r', function()
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
