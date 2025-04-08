return {
  'SearidangPa/hop_copilot.nvim',
  dependencies = {
    'github/copilot.vim',
  },
  config = function()
    vim.keymap.set('i', '<M-s>', require('hop_copilot').hop_copilot, { silent = true, desc = 'hop copilot' })
    vim.keymap.set('i', '<D-s>', require('hop_copilot').hop_copilot, { silent = true, desc = 'hop copilot' })
  end,
}
