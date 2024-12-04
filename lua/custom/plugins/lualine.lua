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
      lualine_c = {
        'harpoon2',
        icon = '♥',
        indicators = { 'a', 's', 'q', 'w' },
        active_indicators = { 'A', 'S', 'Q', 'W' },
        color_active = { fg = '#00ff00' },
        _separator = ' ',
        no_harpoon = 'Harpoon not loaded',
      },
    }
  end,
}
