return {
  {
    'rebelot/kanagawa.nvim',
  },
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    config = function()
      require('rose-pine').setup {
        variant = 'moon',
        disable_italics = true,
      }
    end,
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
