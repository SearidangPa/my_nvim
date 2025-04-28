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

  local max_num_files_displayed = 5
  if vim.fn.has 'win32' == 1 then
    max_num_files_displayed = 4
  end

  table.insert(result, '%#HarpoonFilename#')
  for i = 1, math.min(length, max_num_files_displayed) do
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
  local max_dirs = 2

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

local function is_go_test_file()
  local current_file = vim.fn.expand '%:p'

  if not string.match(current_file, '%.go$') then
    return false
  end

  return string.match(current_file, '_test%.go$') ~= nil
end

return {
  'nvim-lualine/lualine.nvim',
  lazy = true,
  event = 'BufReadPost',
  options = {},
  config = function()
    local ll = require 'lualine'
    require 'config.util_find_func'

    local function nearest_func_name_if_exists()
      if is_go_test_file() then
        return ''
      end
      local func_name = Nearest_func_name()
      if func_name then
        return '%#TabLineSelItalic#' .. func_name .. '%#TabLine#'
      end
      return ''
    end

    vim.api.nvim_set_hl(0, 'TabLineSelItalic', { fg = '#5097A4', italic = true })
    vim.api.nvim_set_hl(0, 'HarpoonFilename', { fg = '#5097A4' })

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
        lualine_c = {},
        lualine_x = { get_harpoon_filenames },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = { nearest_func_name_if_exists },
        lualine_y = { getDirnameAndFilename },
        lualine_z = {},
      },
    }
  end,
}
