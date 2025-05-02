return {
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    lazy = true,
    build = 'make',
    cond = function() return vim.fn.executable 'make' == 1 end,
  },
  {
    'nvim-telescope/telescope.nvim',
    lazy = true,
    version = false,

    config = function()
      local opts = {
        defaults = {
          layout_strategy = 'vertical',
          layout_config = {
            width = 0.7,
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
          fzf = {},
        },
      }

      require('telescope').setup(opts)
      require('custom.telescope_multigrep').setup()
    end,
  },
}
