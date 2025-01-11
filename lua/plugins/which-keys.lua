return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    icons = {
      mappings = vim.g.have_nerd_font,
      keys = vim.g.have_nerd_font and {},
    },

    -- Document existing key chains
    spec = {
      { '<leader>b', group = '[B]rowse' },
      { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
      { '<leader>d', group = '[D]ocument' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { '<leader>m', group = '[M]ake' },
      { '<leader>n', group = '[N]ew' },
      { '<leader>p', group = 'git [P]ush' },
      { '<leader>q', group = '[Q]uickfix' },
      { '<leader>g', group = '[G]o' },
      { '<leader>q', group = '[Q]uickfix' },
      { '<leader>gm', group = '[G]o [M]od' },
      { '<leader>r', group = '[R]ename' },
      { '<leader>s', group = '[S]earch' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>tc', group = '[T]oggle [C]olorscheme', mode = 'n', expr = false, noremap = true },
      { '<leader>w', group = '[W]orkspace' },

      { '<localleader>s', group = '[S]earch plugin' },
    },
  },
}
