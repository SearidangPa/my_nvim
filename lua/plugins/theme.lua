return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = true,
  },
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    lazy = true,
  },

  {
    'rose-pine/neovim',
    name = 'rose-pine',
    lazy = true,
    opts = {
      variant = 'moon',
      styles = {
        italic = false,
      },
    },
  },
  {
    'SearidangPa/theme-loader.nvim',
    lazy = false,
    priority = 1000,
    opts = {},
  },
}
