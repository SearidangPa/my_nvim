local show_func_name = false
vim.keymap.set('n', '<leader>uf', function() show_func_name = not show_func_name end, { desc = 'Toggle function name in statusline' })

local function nearest_func_name_if_exists()
  if not show_func_name then
    return ''
  end
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
  local max_num_files_displayed = 4

  for i = 1, math.min(length, max_num_files_displayed) do
    local path = harpoonList:get(i).value
    local filename = vim.fn.fnamemodify(path, ':t')
    local is_absolute = path:match '^/' or path:match '^%a:' or path:match '^\\\\'
    local fullpath = is_absolute and path or (root_dir .. os_sep .. path)
    if i > 1 then
      table.insert(result, ' | ')
    end
    if fullpath == current_file_path then
      table.insert(result, '[' .. filename .. ']')
    else
      table.insert(result, filename)
    end
  end
  return table.concat(result)
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
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    },
    tabline = {
      lualine_c = {
        {
          nearest_func_name_if_exists,
          color = { fg = '#DCA1A1', gui = 'italic' },
        },
      },
      lualine_x = {
        {
          get_harpoon_filenames,
          color = { fg = '#DCA1A1', gui = 'italic' },
        },
      },
    },
  },
}
