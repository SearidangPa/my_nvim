return {
  'SearidangPa/copilot_hop.nvim',
  dependencies = {
    'github/copilot.vim',
  },
  config = function()
    local copilot_hop = require 'copilot_hop'

    local trigger_key
    if vim.fn.has 'win32' == 1 then
      trigger_key = '<M-S>'
    else
      trigger_key = '<D-s>'
    end

    copilot_hop.setup {
      trigger_key = trigger_key,
    }
  end,
}
