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
        '<localleader><localleader>',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = '[x] Diagnostics',
      },
      {
        '<leader>xb',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = '[x] current [b]uffer',
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
        '<leader>tq',
        '<cmd>Trouble qflist toggle<cr>',
        desc = '[T]oggle Trouble [Q]uickfix',
      },
    },
  },
}
