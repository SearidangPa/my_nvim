local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

-- === Plugins keymaps ===
map('n', '<leader>ut', function() require('theme-loader').toggle_os_theme() end, { desc = '[U]i [T]heme' })
map('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
map('n', '<leader>sb', function() require('fzf-lua').git_branches {} end, { noremap = true, silent = true, desc = '[S]earch remote and local [B]ranches' })
map('n', '<C-S-h>', '<cmd>Treewalker SwapLeft<cr>', { silent = true })
map('n', '<C-S-l>', '<cmd>Treewalker SwapRight<cr>', { silent = true })

map({ 'n', 'x' }, '<leader>gy', function()
  ---@diagnostic disable-next-line: missing-fields
  Snacks.gitbrowse { open = function(url) vim.fn.setreg('+', url) end, notify = false }
end, { desc = 'Git Browse (copy)' })

map({ 'i', 's', 'n' }, '<esc>', function()
  if require('luasnip').expand_or_jumpable() then
    require('luasnip').unlink_current()
  end
  return '<esc>'
end, { desc = 'Escape, clear hlsearch, and stop snippet session', expr = true })

vim.api.nvim_create_user_command('ClearExtmarks', function() vim.api.nvim_buf_clear_namespace(0, -1, 0, -1) end, { nargs = 0 })

map({ 'n', 'i' }, '<C-space>', function() vim.lsp.buf.signature_help() end, map_opt 'Signature help')

map('x', '/', '<Esc>/\\%V', { noremap = true })

vim.api.nvim_create_user_command('CopyCurrentFilePath', function() vim.fn.setreg('+', vim.fn.expand '%:p') end, { nargs = 0 })

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

map({ 'v', 'c' }, '<leader>cc', convert_line_comments_to_block, map_opt '[C]onvert lines to block [C]omment')

return {}
