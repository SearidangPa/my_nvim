local function get_harpoon_filenames(start_idx, end_idx)
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
  local added_count = 0

  for i = start_idx, end_idx do
    if i > length then
      break
    end

    local path = harpoonList:get(i).value
    local filename = vim.fn.fnamemodify(path, ':t:r')
    local is_absolute = path:match '^/' or path:match '^%a:' or path:match '^\\\\'
    local fullpath = is_absolute and path or (root_dir .. os_sep .. path)

    if added_count > 0 then
      table.insert(result, ' | ')
    end

    if fullpath == current_file_path then
      table.insert(result, '[' .. filename .. ']')
    else
      table.insert(result, filename)
    end

    added_count = added_count + 1
  end

  return table.concat(result)
end

local function get_harpoon_filenames_one_two() return get_harpoon_filenames(1, 2) end
local function get_harpoon_filenames_three_four() return get_harpoon_filenames(3, 4) end

local function get_dir_and_filename()
  local function modified_buffer()
    if vim.bo.modified then
      return ' ● ' -- Indicator for unsaved changes
    end
    return ''
  end

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

  return dirs .. '/' .. filename .. modified_buffer()
end

return {
  'nvim-lualine/lualine.nvim',
  version = '*',
  lazy = true,
  event = 'VeryLazy',
  opts = {
    options = {
      globalstatus = true,
    },
    sections = {
      lualine_a = {},
      lualine_b = {
        'diagnostics',
        {
          'FugitiveHead',
          icon = '',
          color = { fg = '#DCA1A1', gui = 'italic' },
        },
        {
          get_dir_and_filename,
          color = { fg = '#3195CA', gui = 'italic' },
        },
      },
      lualine_c = {},
      lualine_x = {
        {
          get_harpoon_filenames_three_four,
          color = { fg = '#FDA5D5' },
        },
      },
      lualine_y = {},
      lualine_z = {},
    },
    tabline = {
      lualine_x = {
        {
          get_harpoon_filenames_one_two,
          color = { fg = '#FDA5D5' },
        },
      },
    },
  },
}
