return {
  'folke/which-key.nvim',
  lazy = true,
  event = 'BufReadPost',
  opts = {
    icons = {
      mappings = vim.g.have_nerd_font,
      keys = vim.g.have_nerd_font and {},
    },

    -- Document existing key chains
    spec = {
      { '<leader>c', group = '[C]olorscheme, [C]lear, [C]urrent, [C]opy', mode = 'n', expr = false, noremap = true },
      { '<leader>d', group = '[D]ocument, [D]elete, [D]ap' },
      { '<leader>e', group = '[E]dit' },
      { '<leader>g', group = ' [G]it' },
      { '<leader>r', group = '[R]ename' },
      { '<leader>s', group = '[S]earch' },
      { '<leader>p', group = '[P]ush' },
      { '<leader>q', group = '[Q]uickfix' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { '<leader>m', group = '[M]ake' },
      { '<leader>n', group = '[N]ew' },
      { '<leader>t', group = '[T]oggle, [T]est Dap' },
      { '<leader>w', group = '[W]orkspace' },
      { '<leader>x', group = '[x] Trouble' },
      { '<localleader>c', group = '[C]ode', mode = { 'n', 'x' } },
      { '<localleader>s', group = '[S]earch plugin' },
      { '<localleader>t', group = '[T]erminal' },
      { '<localleader>x', group = '[Ex]ecute' },
    },
  },
}
