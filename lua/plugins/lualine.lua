local function get_harpoon_filename_func(idx)
  return function()
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

    if idx > length then
      return ''
    end

    local path = harpoonList:get(idx).value
    local filename = vim.fn.fnamemodify(path, ':t:r')
    local is_absolute = path:match '^/' or path:match '^%a:' or path:match '^\\\\'
    local fullpath = is_absolute and path or (root_dir .. os_sep .. path)

    if fullpath == current_file_path then
      table.insert(result, '[' .. filename .. ']')
    else
      table.insert(result, filename)
    end
    return table.concat(result)
  end
end

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
      icons_enabled = true,
      theme = 'auto',
      component_separators = { left = '', right = '' },
      section_separators = { left = '', right = '' },
      disabled_filetypes = {
        statusline = {},
        winbar = {},
      },
      ignore_focus = {},
      always_divide_middle = true,
      always_show_tabline = true,
      globalstatus = true,
      refresh = {
        statusline = 100,
        tabline = 100,
        winbar = 100,
      },
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
      lualine_x = {},
      lualine_y = {
        {
          get_harpoon_filename_func(3),
          color = { fg = '#FDA5D5' },
        },
        {
          get_harpoon_filename_func(4),
          color = { fg = '#FDA5D5' },
        },
      },
      lualine_z = {},
    },

    tabline = {
      lualine_y = {
        {
          get_harpoon_filename_func(1),
          color = { fg = '#FDA5D5' },
        },
        {
          get_harpoon_filename_func(2),
          color = { fg = '#FDA5D5' },
        },
      },
    },
  },
}
