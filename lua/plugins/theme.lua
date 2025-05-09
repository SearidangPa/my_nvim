return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
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
    config = function() require('theme-loader').setup() end,
  },
}
