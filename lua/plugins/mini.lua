return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',
  config = function()
    require('mini.ai').setup { n_lines = 500 }
    require('mini.notify').setup {}
    require('mini.icons').setup {}
    local notify = require 'mini.notify'
    vim.api.nvim_create_user_command('ClearNotify', notify.clear, {})
  end,
}
