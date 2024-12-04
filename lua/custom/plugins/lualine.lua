return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    require 'custom.plugins.harpoon',
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
          'harpoon2',
        },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
    }
  end,
}
