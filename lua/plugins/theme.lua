return {
  {
    'SearidangPa/theme-loader.nvim',
    priority = 1000,
    config = function() require('theme-loader').setup() end,
  },

  {
    'catppuccin/nvim',
    name = 'catppuccin',
    config = true,
    lazy = true,
  },

  {
    'rose-pine/neovim',
    name = 'rose-pine',
    lazy = true,
    config = true,
    opts = {
      variant = 'moon',
      styles = {
        italic = false,
      },
    },
  },
}
