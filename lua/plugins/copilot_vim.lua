return {
  'SearidangPa/copilot_hop.nvim',
  dependencies = {
    'github/copilot.vim',
  },
  config = function()
    vim.g.copilot_no_tab_map = true
    local copilot_hop = require 'copilot_hop'
    copilot_hop.setup()
  end,
}
