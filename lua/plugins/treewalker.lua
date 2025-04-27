return {
  'aaronik/treewalker.nvim',
  lazy = true,
  opts = {
    highlight = false,
    highlight_group = 'CursorLine',
  },
  config = function()
    -- Treewalker swapping
    vim.keymap.set('n', '<M-S-h>', '<cmd>Treewalker SwapLeft<cr>', { silent = true })
    vim.keymap.set('n', '<M-S-l>', '<cmd>Treewalker SwapRight<cr>', { silent = true })
  end,
}
