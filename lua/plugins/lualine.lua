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

    -- Check if path is absolute (starts with / or drive letter on Windows)
    local is_absolute = path:match '^/' or path:match '^%a:' or path:match '^\\'
    local fullpath = is_absolute and path or (root_dir .. os_sep .. path)

    if fullpath == current_file_path then
      list_names = list_names .. display_sep .. '%#TabLineSel#' .. filename .. '%#TabLine#'
    else
      list_names = list_names .. display_sep .. '%#TabLine#' .. filename
    end
  end

  -- remove the first separator
  list_names = list_names:sub(4)

  return list_names
end

local function get_harpoon_filenames_first_half()
  return get_harpoon_filenames {
    start_index = 1,
    end_index = 3,
  }
end

local function getDirnameAndFilename()
  local path = vim.fn.expand '%:p'
  local dirname = vim.fn.fnamemodify(path, ':h:t')
  local filename = vim.fn.fnamemodify(path, ':t')

  return '%#TabLineSelItalic#' .. dirname .. '/' .. filename .. '%#TabLine#'
end

local function tracked_tests_list()
  local terminal_tests = require 'config.terminals_test'
  local test_tracker = terminal_tests.test_tracker
  local list_tests_names = ''
  for test_name, _ in pairs(test_tracker) do
    list_tests_names = list_tests_names .. ' | ' .. test_name
  end
  list_tests_names = list_tests_names:sub(4)
  return '%#TabLineSelItalic#' .. list_tests_names .. '%#TabLine#'
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
        return func_name
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
            fmt = function(str) return str:sub(1, 1) end,
          },
        },
        lualine_b = { 'branch', 'diagnostics' },
        lualine_c = { get_harpoon_filenames_first_half },
        lualine_x = {},
        lualine_y = { nearest_func_name_if_exists },
        lualine_z = {},
      },
      tabline = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { tracked_tests_list },
        lualine_x = { getDirnameAndFilename },
        lualine_y = {},
        lualine_z = {},
      },
    }
  end,
}
