return {
  'SearidangPa/copilot_hop.nvim',
  dependencies = {
    'github/copilot.vim',
  },
  config = function()
    vim.keymap.set('i', '<M-s>', require('copilot_hop').copilot_hop, { silent = true, desc = 'copilot_hop' })
    vim.keymap.set('i', '<D-s>', require('copilot_hop').copilot_hop, { silent = true, desc = 'copilot_hop' })
  end,
}
