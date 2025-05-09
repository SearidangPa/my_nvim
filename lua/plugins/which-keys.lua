return {
  'folke/which-key.nvim',
  lazy = true,
  event = 'BufEnter',
  opts = {
    icons = {
      mappings = vim.g.have_nerd_font,
      keys = vim.g.have_nerd_font and {},
    },

    -- Document existing key chains
    spec = {
      { '<localleader>c', group = '[C]olorscheme, [C]lear, [C]urrent, [C]opy', mode = 'n', expr = false, noremap = true },
      { '<localleader>d', group = '[D]ocument, [D]elete, [D]ap' },
      { '<localleader>e', group = '[E]dit' },
      { '<localleader>g', group = ' [G]it' },
      { '<localleader>r', group = '[R]ename' },
      { '<localleader>s', group = '[S]earch' },
      { '<leader>p', group = '[P]ush' },
      { '<leader>q', group = '[Q]uickfix' },
      { '<localleader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { '<leader>m', group = '[M]ake' },
      { '<localleader>n', group = '[N]ew' },
      { '<localleader>t', group = '[T]oggle, [T]est Dap' },
      { '<localleader>w', group = '[W]orkspace' },
      { '<localleader>x', group = '[x] Trouble' },

      { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
      { '<leader>s', group = '[S]earch' },
      { '<leader>t', group = '[T]erminal' },
      { '<leader>x', group = '[Ex]ecute' },
      { '<leader>h', group = '[H]arpoon', mode = { 'n' } },
      { '<leader>u', group = '[U]i', mode = { 'n' } },
      { '<leader>v', group = '[V]isual', mode = { 'n' } },
    },
  },
}
