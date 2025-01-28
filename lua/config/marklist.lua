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

-- Function to jump to a selected mark
local function jump_to_mark()
  local buf = vim.g.mark_window_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    vim.notify('Mark window buffer is invalid', vim.log.levels.ERROR)
    return
  end

  local line_num = vim.fn.line '.' -- Get the current line number
  local marks = get_global_marks()
  local mark = marks[line_num]
  if not mark then
    vim.notify('Invalid mark selection', vim.log.levels.ERROR)
    return
  end

  -- Switch back to the main window before jumping
  if vim.g.main_window and vim.api.nvim_win_is_valid(vim.g.main_window) then
    vim.api.nvim_set_current_win(vim.g.main_window)
  end

  handle_mark_choice(mark)
end

local function toggle_mark_window()
  if not vim.g.mark_window_buf then
    vim.g.mark_window_buf = nil
  end
  if not vim.g.mark_window_win then
    vim.g.mark_window_win = nil
  end

  -- Store the current window as the main window
  vim.g.main_window = vim.api.nvim_get_current_win()

  if vim.g.mark_window_win and vim.api.nvim_win_is_valid(vim.g.mark_window_win) then
    vim.api.nvim_win_close(vim.g.mark_window_win, true)
    vim.g.mark_window_buf = nil
    vim.g.mark_window_win = nil
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.g.mark_window_buf = buf

  local total_width = vim.o.columns
  local window_width = math.floor(total_width / 5)

  vim.cmd 'vsplit'
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(win, window_width)
  vim.api.nvim_win_set_buf(win, buf)
  vim.g.mark_window_win = win

  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'marklist'
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].wrap = false

  local marks = get_global_marks()
  if #marks == 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'No global marks found' })
    return
  end

  local lines = {}
  for _, mark in ipairs(marks) do
    table.insert(lines, string.format("'%s': %s (%d, %d) -> %s", mark.mark, mark.filename, mark.line, mark.col, mark.text))
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Attach a keymap to jump to the mark on pressing <Enter>
  vim.keymap.set('n', '<CR>', function()
    require('marklist').jump_to_mark()
  end, { noremap = true, silent = true, buffer = buf })
end

vim.keymap.set('n', '<leader>tm', toggle_mark_window, { desc = '[T]oggle [M]ark [W]indow' })

return {
  toggle_mark_window = toggle_mark_window,
  jump_to_mark = jump_to_mark,
}
