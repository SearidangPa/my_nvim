local function nearest_func_name_if_exists()
  local util_find_func = require 'config.util_find_func'

  local func_node = util_find_func.nearest_func_node()

  for child in func_node:iter_children() do
    if child:type() == 'identifier' or child:type() == 'name' then
      local func_name = vim.treesitter.get_node_text(child, 0)
      return func_name
    end
  end
  return ''
end

local function get_dir_and_filename()
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

  local function modified_buffer()
    if vim.bo.modified then
      return ' ● ' -- Indicator for unsaved changes
    end
    return ''
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
        },
        {
          get_dir_and_filename,
          color = { fg = '#F38BA8', gui = 'italic' },
        },
      },
      lualine_c = {},
      lualine_x = {
        {
          nearest_func_name_if_exists,
          color = { fg = '#DCA1A1', gui = 'italic' },
        },
      },
      lualine_y = {},
      lualine_z = {},
    },
  },
}
