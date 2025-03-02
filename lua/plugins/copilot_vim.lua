return {
  'SearidangPa/copilot_hop.nvim',
  dependencies = {
    'github/copilot.vim',
  },
  config = function()
    local copilot_hop = require 'copilot_hop'

    local triggerkey
    if vim.fn.has 'win32' == 1 then
      triggerkey = '<M-S>'
    else
      triggerkey = '<D-s>'
    end

    vim.keymap.set('i', triggerkey, copilot_hop.copilot_hop(), { expr = true, silent = true, description = 'copilot_hop' })
  end,
}
