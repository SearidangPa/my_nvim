return {
  'folke/which-key.nvim',
  lazy = true,
  event = 'VeryLazy',
  opts = {
    icons = {
      mappings = vim.g.have_nerd_font,
      keys = vim.g.have_nerd_font and {},
    },

    -- Document existing key chains
    spec = {
      { '<localleader>a', group = '[a]i' },
      { '<localleader>f', group = '[f]iles' },
      { '<localleader>d', group = '[d]elete' },
      { '<localleader>r', group = '[r]ename' },
      { '<localleader>t', group = '[T]oggle' },
      { '<localleader>x', group = '[x] Trouble' },

      { '<leader>m', group = '[M]ake' },
      { '<leader>g', group = '[G]it' },
      { '<leader>h', group = '[H]arpoon', mode = { 'n' } },
      { '<leader>p', group = '[P]ush' },
      { '<leader>q', group = '[Q]uickfix' },
      { '<leader>s', group = '[S]earch' },
      { '<leader>t', group = '[T]erminal' },
      { '<leader>u', group = '[U]i', mode = { 'n' } },
      { '<leader>v', group = '[V]isual', mode = { 'n' } },
      { '<leader>y', group = '[Y]ank', mode = { 'n' } },
    },
  },
}
