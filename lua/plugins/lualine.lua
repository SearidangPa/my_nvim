local function get_harpoon_filenames()
  local harpoon = require 'harpoon'
  local harpoonList = harpoon:list()
  local length = harpoonList:length()

  if length == 0 then
    return ''
  end

  local root_dir = harpoonList.config:get_root_dir()
  local os_sep = vim.fn.has 'win32' == 1 and '\\' or '/'
  local current_file_path = vim.api.nvim_buf_get_name(0)
  local result = {}

  for i = 1, math.min(length, 3) do
    local path = harpoonList:get(i).value
    local filename = vim.fn.fnamemodify(path, ':t')
    local is_absolute = path:match '^/' or path:match '^%a:' or path:match '^\\\\'
    local fullpath = is_absolute and path or (root_dir .. os_sep .. path)

    if i > 1 then
      table.insert(result, ' | ')
    end

    if fullpath == current_file_path then
      table.insert(result, '[' .. filename .. ']') -- We'll use a visual marker instead
    else
      table.insert(result, filename)
    end
  end

  return table.concat(result)
end

local function tracked_tests_first_half()
  local terminal_tests = require 'config.terminals_test'
  local test_tracker = terminal_tests.test_tracker
  local list_tests_names = ''
  local index = 1
  for _, test_info in ipairs(test_tracker) do
    list_tests_names = list_tests_names .. ' | ' .. test_info.test_name
    index = index + 1
    if index > 3 then
      break
    end
  end
  list_tests_names = list_tests_names:sub(4)
  return '%#TabLineSelItalic#' .. list_tests_names .. '%#TabLine#'
end

local function modified_buffer()
  if vim.bo.modified then
    return '● ' -- Indicator for unsaved changes
  end
  return ''
end

local function getDirnameAndFilename()
  local path = vim.fn.expand '%:p'
  local filename = vim.fn.fnamemodify(path, ':t')
  local full_dir = vim.fn.fnamemodify(path, ':h')
  local dir_parts = {}
  local dir_count = 0
  local max_dirs = 1

  while dir_count < max_dirs do
    local dirname = vim.fn.fnamemodify(full_dir, ':t')
    if dirname == '' or dirname == '/' or dirname == full_dir then
      break
    end
    table.insert(dir_parts, 1, dirname)
    dir_count = dir_count + 1
    full_dir = vim.fn.fnamemodify(full_dir, ':h')
  end

  local dirs = table.concat(dir_parts, '/')
  if dirs == '' then
    dirs = vim.fn.fnamemodify(path, ':h:t')
  end

  return modified_buffer() .. dirs .. '/' .. filename
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
        return '%#TabLineSelItalic#' .. func_name .. '%#TabLine#'
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
            show_modified_status = true,
          },
        },
        lualine_b = { 'branch', 'diagnostics' },
        lualine_c = { get_harpoon_filenames },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {
        lualine_a = {},
        lualine_b = { tracked_tests_first_half },
        lualine_c = {},
        lualine_x = { nearest_func_name_if_exists },
        lualine_y = { getDirnameAndFilename },
        lualine_z = {},
      },
    }
  end,
}
