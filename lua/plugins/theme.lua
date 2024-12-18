return {
  {
    'rebelot/kanagawa.nvim',
    priority = 1000,
    init = function()
      vim.cmd.colorscheme 'kanagawa-wave'
      vim.cmd.hi 'Comment gui=none'
    end,
  },
  { 'rose-pine/neovim', name = 'rose-pine' },
  { 'folke/tokyonight.nvim', lazy = false, priority = 1000 },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    -- init = function()
    --   vim.cmd.colorscheme 'catppuccin-latte'
    --   vim.cmd.hi 'Comment gui=none'
    -- end,
  },
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    priority = 1000,
  },
}
