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
    config = function() require('theme-loader').setup() end,
    lazy = true,
    event = 'VeryLazy',
  },
}
