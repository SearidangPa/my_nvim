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
      options = {
        globalstatus = true,
      },
      sections = {
        lualine_a = {
          {
            'mode',
            fmt = function(str)
              return str:sub(1, 1)
            end,
          },
        },
        lualine_b = { 'branch', 'diagnostics' },
        lualine_c = {
          {
            'filename',
            path = 4,
          },
        },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {
          {
            'harpoon2',
            indicators = { '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' },
          },
        },
      },
    }
  end,
}
