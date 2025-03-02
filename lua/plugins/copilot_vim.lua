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

    print('copilot_hop.setup', triggerkey)
    copilot_hop.setup {
      triggerkey = triggerkey,
    }
  end,
}
