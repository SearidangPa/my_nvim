require 'config.util_find_func'

local function set_filetype_by_extension(filename, bufnr)
  -- Get the filename of the buffer
  -- Extract the file extension
  local ext = filename:match '^.+%.(.+)$'
  if not ext then
    print('No file extension found for buffer ' .. filename)
    return
  end

  -- Map file extensions to filetypes
  local filetype_map = {
    go = 'go',
    lua = 'lua',
    py = 'python',
    -- Add more extensions as needed
  }

  -- Set the filetype if it's in the map
  local filetype = filetype_map[ext]
  if filetype then
    vim.bo[bufnr].filetype = filetype
  else
    print('No filetype mapping for extension: ' .. ext)
  end
end

local function get_global_marks()
  local marks = {}
  local cwd = vim.fn.getcwd() -- Get the current working directory
  for char = string.byte 'A', string.byte 'Z' do
    local mark = string.char(char)
    local pos = vim.fn.getpos("'" .. mark)
    if pos[1] ~= 0 then -- Check if the mark is valid
      local bufnr = pos[1]
      local line = pos[2]
      local col = pos[3]
      local filepath = vim.fn.bufname(bufnr)
      local abs_filepath = vim.fn.fnamemodify(filepath, ':p') -- Convert to absolute path
      -- Check if the file is under the current working directory
      if abs_filepath:find(cwd, 1, true) then
        local filename = vim.fn.fnamemodify(filepath, ':t') -- Get only the file name

        set_filetype_by_extension(filename, bufnr)
        local nearest_func_at_line = Nearest_function_at_line(bufnr, line)
        table.insert(marks, {
          mark = mark,
          bufnr = bufnr,
          filename = filename ~= '' and filename or '[No Name]',
          filepath = abs_filepath,
          line = line,
          col = col,
          nearest_func = nearest_func_at_line,
          text = vim.fn.getbufline(bufnr, line)[1],
        })
      end
    end
  end
  return marks
end

local function get_local_marks()
  local marks = {}
  local cwd = vim.fn.getcwd() -- Get the current working directory
  local mark_list = vim.fn.getmarklist(0) -- Get marks for the current buffer only

  for _, mark_entry in ipairs(mark_list) do
    local mark = mark_entry.mark:sub(2, 2) -- Extract the mark character (e.g., 'a', 'b', ...)
    if mark:match '[a-z]' then -- Ensure it's a local mark
      local bufnr = mark_entry.pos[1]
      local line = mark_entry.pos[2]
      local col = mark_entry.pos[3]

      if vim.api.nvim_buf_is_valid(bufnr) then
        local filepath = vim.fn.bufname(bufnr)
        local abs_filepath = vim.fn.fnamemodify(filepath, ':p')

        local filename = vim.fn.fnamemodify(filepath, ':t')
        local nearest_func_at_line = Nearest_function_at_line(bufnr, line)
        -- Get the text safely
        local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''

        table.insert(marks, {
          mark = mark,
          bufnr = bufnr,
          filename = filename ~= '' and filename or '[No Name]',
          filepath = abs_filepath,
          line = line,
          col = col,
          nearest_func = nearest_func_at_line,
          text = text,
        })
      end
    end
  end
  return marks
end

--------------------------------------------------------------------------------
-- Jump to Mark: parse the line in the mark window to find the mark character. --
--------------------------------------------------------------------------------
local function jump_to_mark()
  local buf = vim.g.mark_window_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    vim.notify('Mark window buffer is invalid', vim.log.levels.ERROR)
    return
  end

  -- Get the text of the current line in the mark window
  local line_num = vim.fn.line '.'
  local line_text = vim.fn.getline(line_num)

  -- Attempt to extract the mark character from something like:
  --   ├─ 'A': (120, 1) -> some text
  -- or
  --   'A': (120, 1) -> some text
  -- The pattern captures an uppercase letter hin single quotes.
  local mark_char = line_text:match '([A-Z]):' or line_text:match '([a-z]):'
  if not mark_char then
    -- Possibly on a filename line or invalid line
    print(string.format('No mark character found in line %d: %s', line_num, line_text))
    return
  end

  -- Switch back to the main window (so the jump happens there)
  if vim.g.main_window and vim.api.nvim_win_is_valid(vim.g.main_window) then
    vim.api.nvim_set_current_win(vim.g.main_window)
  end

  -- Use backtick-jump to go precisely to the mark position
  vim.cmd('normal! `' .. mark_char)
  vim.cmd 'normal! zz'
end

--------------------------------------------------------------------------------
-- Toggle a scratch window on the right that displays all global marks, grouped
-- by filename, in a tree-like format.
--------------------------------------------------------------------------------
local function toggle_mark_window()
  -- Track window/buffer state
  if not vim.g.mark_window_buf then
    vim.g.mark_window_buf = nil
  end
  if not vim.g.mark_window_win then
    vim.g.mark_window_win = nil
  end

  -- Store the current window as 'main_window'
  vim.g.main_window = vim.api.nvim_get_current_win()

  -- If the marks window is already open, close it
  if vim.g.mark_window_win and vim.api.nvim_win_is_valid(vim.g.mark_window_win) then
    vim.api.nvim_win_close(vim.g.mark_window_win, true)
    vim.g.mark_window_buf = nil
    vim.g.mark_window_win = nil
    return
  end

  -- Create a new scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.g.mark_window_buf = buf

  -- Calculate the width for a 1/5 vertical split
  local total_width = vim.o.columns
  local window_width = math.floor(total_width / 5)

  -- Open the vertical split
  vim.cmd 'vsplit'
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(win, window_width)
  vim.api.nvim_win_set_buf(win, buf)
  vim.g.mark_window_win = win

  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = vim.g.mark_window_buf,
    callback = function()
      jump_to_mark()
      vim.api.nvim_set_current_win(vim.g.mark_window_win)
    end,
  })

  -- Set buffer/window options
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].wrap = false

  -- Retrieve global marks
  local global_marks = get_global_marks()
  local local_marks = get_local_marks()
  local all_marks = vim.list_extend(global_marks, local_marks)

  if #all_marks == 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'No global marks found' })
    return
  end

  -- Group marks by filename
  local grouped_marks = {}
  for _, m in ipairs(all_marks) do
    local filename = m.filename
    if not grouped_marks[filename] then
      grouped_marks[filename] = {}
    end
    table.insert(grouped_marks[filename], m)
  end

  -- We'll store the lines in this array, and keep track of filename line indices
  local lines = {}
  local filename_line_indices = {} -- holds line numbers that are filenames

  -- Build a tree-like display:
  for filename, marks in pairs(grouped_marks) do
    -- Record the line index of this filename
    local filename_line_idx = #lines -- zero-based index AFTER insertion
    table.insert(lines, filename)
    table.sort(marks, function(a, b)
      return a.mark < b.mark
    end)
    for _, mark in ipairs(marks) do
      table.insert(lines, string.format(' ├─ %s: %s', mark.mark, mark.nearest_func or mark.text or ''))
    end
    -- `filename_line_idx` was the index before adding the filename line.
    -- So the real line for highlight is that index we just used.
    filename_line_indices[#filename_line_indices + 1] = filename_line_idx
  end

  -- Write the lines into the buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  ----------------------------------------------------------------------------
  -- 1) Define a new highlight group for the filenames.
  --    (We do it here so that it doesn't get reset on every new buffer.)
  ----------------------------------------------------------------------------
  vim.api.nvim_set_hl(0, 'MarkListFile', { fg = '#5097A4' })
  -- Adjust the color code to your favorite "light green" or any other color.

  ----------------------------------------------------------------------------
  -- 2) Highlight each filename line using the new highlight group.
  ----------------------------------------------------------------------------
  for _, line_idx in ipairs(filename_line_indices) do
    -- The 4th argument sets the start column to 0, the 5th to -1 => highlight entire line
    vim.api.nvim_buf_add_highlight(buf, -1, 'MarkListFile', line_idx, 0, -1)
  end

  -- Attach a keymap to jump to the mark on pressing <Enter>
  vim.keymap.set('n', '<CR>', function()
    require('config.marklist').jump_to_mark()
  end, { noremap = true, silent = true, buffer = buf })
end

vim.keymap.set('n', '<leader>tm', toggle_mark_window, { desc = '[T]oggle [M]arklist' })

-- Return the module’s functions
return {
  toggle_mark_window = toggle_mark_window,
  jump_to_mark = jump_to_mark,
}
