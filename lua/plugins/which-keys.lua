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
      { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
      { '<leader>d', group = '[D]ocument' },
      { '<leader>r', group = '[R]ename' },
      { '<leader>s', group = '[S]earch' },
      { '<leader>w', group = '[W]orkspace' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>tc', group = '[T]oggle [C]olorscheme', mode = 'n', expr = false, noremap = true },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { '<leader>m', group = '[M]ake' },
      { '<leader>q', group = '[Q]uickfix' },
      { '<leader>b', group = '[B]rowse' },
      { '<leader>p', group = 'git [P]ush' },
      { '<leader>g', group = '[G]o' },
      { '<leader>gm', group = '[G]o [M]od' },

      { '<localleader>s', group = '[S]earch plugin' },
      { '<localleader>t', group = '[T]oggle make result' },
    },
  },
}
