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
        '<leader>xd',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = '[T]oggle [D]iagnostics',
      },
      {
        '<localleader>xd',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = 'Toggle [D]iagnostics for the current buffer',
      },
      {
        '<leader>xs',
        '<cmd>Trouble symbols toggle focus=false<cr>',
        desc = '[T]oggle [S]ymbols',
      },
      {
        '<leader>xls',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        desc = '[T]oggle [L]SP Definitions / references / ... (Trouble)',
      },
      {
        '<leader>xll',
        '<cmd>Trouble loclist toggle<cr>',
        desc = '[T]rouble [L]ocation list (Trouble)',
      },
      {
        '<leader>xq',
        '<cmd>Trouble qflist toggle<cr>',
        desc = '[T]oggle [Q]uickfix',
      },
    },
  },
}
