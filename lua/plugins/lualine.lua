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

local function getDirnameAndFilename()
  local path = vim.fn.expand '%:p'
  local filename = vim.fn.fnamemodify(path, ':t')

  -- Get full directory path
  local full_dir = vim.fn.fnamemodify(path, ':h')

  -- Get last 3 directory components
  local dir_parts = {}
  local dir_count = 0
  local max_dirs = 1

  -- Extract directory components, working backwards
  while dir_count < max_dirs do
    local dirname = vim.fn.fnamemodify(full_dir, ':t')

    -- Stop if we reached the root
    if dirname == '' or dirname == '/' or dirname == full_dir then
      break
    end

    table.insert(dir_parts, 1, dirname)
    dir_count = dir_count + 1

    -- Move up one directory level
    full_dir = vim.fn.fnamemodify(full_dir, ':h')
  end

  -- Join directory parts with separator
  local dirs = table.concat(dir_parts, '/')

  -- If no directory components were found, use the immediate parent
  if dirs == '' then
    dirs = vim.fn.fnamemodify(path, ':h:t')
  end

  return '%#TabLineSelItalic#' .. dirs .. '/' .. filename .. '%#TabLine#'
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
    local toggle_nearest_func

    local function nearest_func_name_if_exists()
      if not toggle_nearest_func then
        return ''
      end
      local func_name = Nearest_func_name()
      if func_name then
        return func_name
      end
      return ''
    end
    vim.api.nvim_create_user_command('LualineToggleNearestFunc', function() toggle_nearest_func = not toggle_nearest_func end, { nargs = 0 })

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
        lualine_c = { tracked_tests_first_half },
        lualine_x = { getDirnameAndFilename },
        lualine_y = {},
        lualine_z = {},
      },
    }
  end,
}
