return {
  'kevinhwang91/nvim-bqf',
  ft = 'qf',
  dependencies = {
    {
      'junegunn/fzf',
      run = function()
        vim.fn['fzf#install']()
      end,
    },
    {
      'nvim-treesitter/nvim-treesitter',
      run = ':TSUpdate',
    },
  },
  config = function()
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- Assuming QfSession is available in your Lua runtime path
    local QfSession = require 'bqf.qfwin.session'

    -- Keybinding to dispose of quickfix sessions
    -- '<cmd>lua require("bqf"):dispose()<CR>', opts)
    map('n', '<leader>qd', function()
      QfSession:dispose()
    end, opts)
  end,
}
