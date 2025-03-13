return {
  'SearidangPa/copilot_hop.nvim',
  dependencies = {
    'github/copilot.vim',
  },
  config = function()
    local copilot_hop = require 'copilot_hop'
    copilot_hop.setup()
    vim.keymap.set('i', '<C-s>', copilot_hop.copilot_hop, { silent = true, desc = 'copilot_hop' })
  end,
}
