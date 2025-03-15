return {
  'SearidangPa/blackboard.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local bb = require 'blackboard'
    vim.keymap.set('n', '<leader>tm', bb.toggle_mark_window, { desc = '[T]oggle [M]ark list window' })
  end,
}
