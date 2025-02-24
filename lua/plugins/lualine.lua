local function get_harpoon_filenames(opts)
  local harpoon = require 'harpoon'
  local root_dir = harpoon:list().config:get_root_dir()
  local harpoonList = harpoon:list()
  local length = harpoonList:length()

  local start_index = opts.start_index or 1
  local end_index = opts.end_index or 3
  if end_index > length then
    end_index = length
  end

  if length < start_index then
    return ''
  end

  local os_sep = '/'
  if vim.fn.has 'win32' == 1 then
    os_sep = '\\'
  end

  local list_names = ''
  local current_file_path = vim.api.nvim_buf_get_name(0)

  for i = start_index, end_index do
    local display_sep = ' | '
    local val_at_index = harpoonList:get(i)
    local path = val_at_index.value
    local filename = vim.fn.fnamemodify(path, ':t')
    local fullpath = root_dir .. os_sep .. path

    if fullpath == current_file_path then
      list_names = list_names .. display_sep .. '%#TabLineSel#' .. filename .. '%#TabLine#'
    else
      list_names = list_names .. display_sep .. filename
    end
  end

  -- remove the first separator
  list_names = list_names:sub(4)

  return list_names
end

local function get_harpoon_filenames_second_half()
  return get_harpoon_filenames {
    start_index = 4,
    end_index = 6,
  }
end

local function get_harpoon_filenames_first_three()
  return get_harpoon_filenames {
    start_index = 1,
    end_index = 3,
  }
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
    require 'config.util_find_func'

    local function nearest_func_name_if_exists()
      local func_name = Nearest_func_name()
      if func_name then
        return '%#TabLineSelItalic#' .. func_name
      end
      return ''
    end
    vim.api.nvim_set_hl(0, 'TabLineSelItalic', { fg = '#5097A4', italic = true })

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
        lualine_c = { { 'filename', path = 3 } },
        lualine_x = { nearest_func_name_if_exists },
        lualine_y = { get_harpoon_filenames_second_half },
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
        lualine_y = { get_harpoon_filenames_first_three },
        lualine_z = {},
      },
    }
  end,
}
