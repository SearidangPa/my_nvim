local function get_harpoon_filenames()
  local harpoon = require 'harpoon'
  local root_dir = harpoon:list().config:get_root_dir()
  local harpoonList = harpoon:list()
  local length = harpoonList:length()

  local os_sep = '/'
  if vim.fn.has 'win32' == 1 then
    os_sep = '\\'
  end

  local list_names = ''
  local current_file_path = vim.api.nvim_buf_get_name(0)

  for i = 1, length do
    local display_sep = ' | '
    local val_at_index = harpoonList:get(i)
    local path = val_at_index.value
    local tokens = vim.split(path, os_sep)
    local fullpath = root_dir .. os_sep .. path

    if fullpath == current_file_path then
      display_sep = ' |* '
    end

    list_names = list_names .. display_sep .. tokens[#tokens]
  end

  return list_names
end

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
            active_indicators = { '[1]', '[2]', '[3]', '[4]', '[5]', '[6]', '[7]', '[8]', '[9]', '[10]' },
          },
        },
      },
      tabline = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = { get_harpoon_filenames },
        lualine_z = {},
      },
    }
  end,
}
