return {
  'SearidangPa/blackboard.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local bb = require 'blackboard'
    local function wait_for_key_and_preview()
      local key = vim.fn.getcharstr() -- Waits for user input
      if not key or key == '' then
        return
      end
      bb.preview_mark(key)
    end
    vim.keymap.set('n', '<leader>tm', bb.toggle_mark_window, { desc = '[T]oggle [M]ark list window' })
    vim.keymap.set('n', '<localleader>m', wait_for_key_and_preview, { desc = 'Preview [M]ark' })
  end,
}
