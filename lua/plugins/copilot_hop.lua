return {
  'SearidangPa/hopcopilot.nvim',
  dependencies = {
    'github/copilot.vim',
  },
  config = function()
    local hopcopilot = require 'hopcopilot'
    hopcopilot.setup()
    vim.keymap.set('i', '<M-s>', hopcopilot.hop_copilot, { silent = true, desc = 'hop copilot' })
    vim.keymap.set('i', '<D-s>', hopcopilot.hop_copilot, { silent = true, desc = 'hop copilot' })
  end,
}
