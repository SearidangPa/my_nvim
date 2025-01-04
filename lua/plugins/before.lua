return {
  'bloznelis/before.nvim',
  config = function()
    local before = require 'before'
    before.setup()
    vim.keymap.set('n', '<leader>qe', before.show_edits_in_quickfix, { desc = '[Q]uickfix [E]dit history' })
    vim.keymap.set('n', '<leader>se', before.show_edits_in_telescope, { desc = '[S]earch [E]dit history' })
  end,
}
