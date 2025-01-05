return {
  {
    'rebelot/kanagawa.nvim',
    priority = 1000,
    config = function()
      require('kanagawa').setup {
        theme = 'wave',
      }
    end,
  },
  { 'rose-pine/neovim', name = 'rose-pine' },
  { 'folke/tokyonight.nvim', lazy = false },
  {
    'navarasu/onedark.nvim',
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
  },
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
  },
}
