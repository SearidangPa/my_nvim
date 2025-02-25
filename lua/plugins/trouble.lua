return {
  'folke/trouble.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  opts = {},
  cmd = 'Trouble',
  keys = {
    {
      '<leader><leader>',
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
  },
}
