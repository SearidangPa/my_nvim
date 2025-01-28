-- Gathers all global marks
local function get_global_marks()
  local marks = {}
  for char = string.byte 'A', string.byte 'Z' do
    local mark = string.char(char)
    local pos = vim.fn.getpos("'" .. mark)
    if pos[1] ~= 0 then -- Check if the mark is valid
      local bufnr = pos[1]
      local line = pos[2]
      local col = pos[3]
      local filepath = vim.fn.bufname(bufnr)
      local filename = vim.fn.fnamemodify(filepath, ':t') -- Get only the file name
      table.insert(marks, {
        mark = mark,
        bufnr = bufnr,
        filename = filename ~= '' and filename or '[No Name]',
        line = line,
        col = col,
        text = vim.fn.getbufline(bufnr, line)[1],
      })
    end
  end
  return marks
end

-- For quickselect UI (optional in your setup)
local function handle_mark_choice(choice)
  if not choice then
    vim.notify('No mark selected', vim.log.levels.INFO)
    return
  end
  local line, col, bufnr = choice.line, choice.col, choice.bufnr
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_win_set_cursor(0, { line, col })
  vim.cmd 'normal! zz'
end

-- Optional: If you want a quick UI select for global marks
local function select_mark()
  local marks = get_global_marks()
  if #marks == 0 then
    vim.notify('No global marks found', vim.log.levels.INFO)
    return
  end

  local opts = {
    prompt = 'Select mark:',
    format_item = function(item)
      return string.format("'%s': %s -> %s", item.mark, item.filename, item.text)
    end,
  }

  vim.ui.select(marks, opts, function(choice)
    handle_mark_choice(choice)
  end)
end

vim.keymap.set('n', '<leader>gm', select_mark, { desc = '[G]lobal [M]ark' })

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
  -- The pattern captures an uppercase letter within single quotes.
  local mark_char = line_text:match "'([A-Z])':"
  if not mark_char then
    -- Possibly on a filename line or invalid line
    vim.notify('No valid mark found on this line.', vim.log.levels.ERROR)
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

  -- Set buffer/window options
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'marklist'
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].wrap = false

  -- Retrieve global marks
  local all_marks = get_global_marks()
  if #all_marks == 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'No global marks found' })
    return
  end

  ----------------------------------------------------------------------------
  -- Group marks by filename and format them in a tree-like structure.
  ----------------------------------------------------------------------------
  local grouped_marks = {}
  for _, m in ipairs(all_marks) do
    local filename = m.filename
    if not grouped_marks[filename] then
      grouped_marks[filename] = {}
    end
    table.insert(grouped_marks[filename], m)
  end

  local lines = {}
  for filename, marks in pairs(grouped_marks) do
    -- Show the filename
    table.insert(lines, filename)
    -- Under each filename, list marks with an indent and tree arrow
    for _, mark in ipairs(marks) do
      table.insert(lines, string.format("  ├─ '%s': (%d, %d) -> %s", mark.mark, mark.line, mark.col, mark.text or ''))
    end
  end

  -- Render lines in the buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Use vim.keymap.set for a Lua function that calls jump_to_mark
  vim.keymap.set('n', '<CR>', function()
    require('config.marklist').jump_to_mark()
  end, { noremap = true, silent = true, buffer = buf })
end

-- Keymap to toggle the mark window
vim.keymap.set('n', '<leader>tm', toggle_mark_window, { desc = '[T]oggle [M]ark [W]indow' })

-- Return the module’s functions
return {
  toggle_mark_window = toggle_mark_window,
  jump_to_mark = jump_to_mark,
}
