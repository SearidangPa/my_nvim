return {
  'SearidangPa/hopcopilot.nvim',
  dependencies = {
    'github/copilot.vim',
  },
  config = function()
    vim.keymap.set('i', '<M-s>', require('hopcopilot').hop_copilot, { silent = true, desc = 'hop copilot' })
    vim.keymap.set('i', '<D-s>', require('hopcopilot').hop_copilot, { silent = true, desc = 'hop copilot' })
  end,
}
