return {
  'SearidangPa/copilot_hop.nvim',
  dependencies = {
    'github/copilot.vim',
  },
  config = function()
    local trigger_key
    if vim.fn.has 'win32' == 1 then
      trigger_key = '<M-S>'
    else
      trigger_key = '<D-s>'
    end

    local copilot_hop = require 'copilot_hop'
    copilot_hop.setup()
    vim.keymap.set('i', trigger_key, copilot_hop.copilot_hop, { silent = true, desc = 'copilot_hop' })
  end,
}
