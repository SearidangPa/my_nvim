local map = vim.keymap.set

return {
  'aaronik/treewalker.nvim',
  opts = {
    highlight = false,
    highlight_group = 'CursorLine',
  },
  config = function()
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
  end,
}
