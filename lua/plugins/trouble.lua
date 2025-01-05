return {
  {
    'folke/trouble.nvim',
    dependencies = {
      'nvim-telescope/telescope.nvim',
    },
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = 'Trouble',
    keys = {
      {
        '<leader>xx',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'Diagnostics (Trouble)',
      },
      {
        '<leader>xX',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = 'Buffer Diagnostics (Trouble)',
      },
      {
        '<leader>ts',
        '<cmd>Trouble symbols toggle focus=false<cr>',
        desc = '[T]oggle [S]ymbols',
      },
      {
        '<leader>tl',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        desc = '[T]oggle [L]SP Definitions / references / ... (Trouble)',
      },
      {
        '<leader>xl',
        '<cmd>Trouble loclist toggle<cr>',
        desc = '[T]rouble [L]ocation list (Trouble)',
      },
      {
        '<leader>tq',
        '<cmd>Trouble qflist toggle<cr>',
        desc = '[T]rouble [Q]uickfix',
      },
    },
    config = function()
      local open_with_trouble = require('trouble.sources.telescope').open
      local telescope = require 'telescope'
      telescope.setup {
        defaults = {
          mappings = {
            i = { ['<c-t>'] = open_with_trouble },
            n = { ['<c-t>'] = open_with_trouble },
          },
        },
      }
    end,
  },
}
