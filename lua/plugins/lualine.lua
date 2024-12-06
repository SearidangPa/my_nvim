return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    require 'plugins.harpoon',
  },
  options = {
    theme = 'gruvbox',
    section_separators = { left = '', right = '' },
    component_separators = { left = '', right = '' },
  },
  config = function()
    local ll = require 'lualine'
    ll.setup {
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diagnostics' },
        lualine_c = {
          'filename',
          {
            'harpoon2',
            indicators = { '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' },
          },
        },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
    }
  end,
}
