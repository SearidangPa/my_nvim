return {
  'folke/trouble.nvim',
  lazy = true,
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  opts = {},
  cmd = 'Trouble',
  keys = {
    {
      '<leader>ts',
      '<cmd>Trouble symbols toggle focus=false<cr>',
      desc = '[T]oggle [S]ymbols',
    },
    {
      '<leader>xq',
      '<cmd>Trouble qflist toggle<cr>',
      desc = 'Quickfix List (Trouble)',
    },
    {
      '<leader>xb',
      '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
      desc = '[x] current [b]uffer',
    },
    {
      '<leader>xx',
      '<cmd>Trouble diagnostics toggle<cr>',
      desc = '[x] Diagnostics',
    },
  },
}
