return {
  'folke/trouble.nvim',
  lazy = true,
  event = { 'VeryLazy', 'BufReadPost' },

  opts = {
    ---@type trouble.Window.opts
    win = {
      size = {
        height = 5,
      },
    },
  }, -- for default options, refer to the configuration section for custom setup.
  cmd = 'Trouble',
  keys = {
    {
      '<localleader><localleader>',
      '<cmd>Trouble diagnostics toggle<cr>',
      desc = 'Diagnostics (Trouble)',
    },
    {
      '<leader>ts',
      '<cmd>Trouble symbols toggle focus=false<cr>',
      desc = 'Symbols (Trouble)',
    },
    {
      '<leader>tt',
      '<cmd>Trouble toggle snacks<cr>',
      desc = 'Toggle Trouble Window',
    },
    {
      ']d',
      function()
        local tr = require 'trouble'
        ---@diagnostic disable-next-line: missing-fields
        tr.next {}
        ---@diagnostic disable-next-line: missing-fields
        tr.jump {}
      end,
      desc = 'Next Trouble Item',
    },
    {
      '[d',
      function()
        local tr = require 'trouble'
        ---@diagnostic disable-next-line: missing-fields
        tr.prev {}
        ---@diagnostic disable-next-line: missing-fields
        tr.jump {}
      end,
      desc = 'Previous Trouble Item',
    },
  },
  specs = {
    'folke/snacks.nvim',
    opts = function(_, opts)
      return vim.tbl_deep_extend('force', opts or {}, {
        picker = {
          actions = require('trouble.sources.snacks').actions,
          win = {
            input = {
              keys = {
                ['<c-t>'] = {
                  'trouble_open',
                  mode = { 'n', 'i' },
                },
              },
            },
          },
        },
      })
    end,
  },
}
