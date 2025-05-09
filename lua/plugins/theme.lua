return {
  {
    'SearidangPa/theme-loader.nvim',
    dependencies = {
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
    },
    lazy = false,
    priority = 1000,
    config = function() require('theme-loader').setup() end,
  },
}
