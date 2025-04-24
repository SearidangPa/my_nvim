return {
  'nvim-telescope/telescope.nvim',
  lazy = true,
  event = 'VimEnter',
  version = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function() return vim.fn.executable 'make' == 1 end,
    },
    { 'nvim-telescope/telescope-dap.nvim' },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },

  config = function()
    local builtin = require 'telescope.builtin'
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
    require('telescope').load_extension 'fzf'
    require('telescope').load_extension 'ui-select'
    require('telescope').load_extension 'harpoon'
    require('telescope').load_extension 'dap'
    require('telescope').load_extension 'fidget'
    require('config.telescope_multigrep').setup()
  end,
}
