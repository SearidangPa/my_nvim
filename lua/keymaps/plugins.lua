local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

map('n', '<leader>ut', function() require('theme-loader').toggle_os_theme() end, { desc = '[U]i [T]heme' })
map('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
map('n', '<leader>sb', function() require('fzf-lua').git_branches {} end, { noremap = true, silent = true, desc = '[S]earch remote and local [B]ranches' })
map('n', '<C-S-h>', '<cmd>Treewalker SwapLeft<cr>', { silent = true })
map('n', '<C-S-l>', '<cmd>Treewalker SwapRight<cr>', { silent = true })

map({ 'i', 's', 'n' }, '<esc>', function()
  if require('luasnip').expand_or_jumpable() then
    require('luasnip').unlink_current()
  end
  return '<esc>'
end, { desc = 'Escape, clear hlsearch, and stop snippet session', expr = true })

---@diagnostic disable-next-line: missing-fields
map({ 'n', 'x' }, '<leader>gy', function()
  Snacks.gitbrowse { open = function(url) vim.fn.setreg('+', url) end, notify = false }
end, map_opt '[G]it [Y]ank URL')

return {}
