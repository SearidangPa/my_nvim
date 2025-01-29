require 'config.util_find_func'
require 'config.util_marklist'
require 'config.util_highlight'

local function jump_to_mark()
  local buf = vim.g.mark_window_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    vim.notify('Mark window buffer is invalid', vim.log.levels.ERROR)
    return
  end

  local line_num = vim.fn.line '.'
  local line_text = vim.fn.getline(line_num)

  local mark_char = line_text:match '([A-Z]):' or line_text:match '([a-z]):'
  if not mark_char then
    print(string.format('No mark character found in line %d: %s', line_num, line_text))
    return
  end

  if vim.g.main_window and vim.api.nvim_win_is_valid(vim.g.main_window) then
    vim.api.nvim_set_current_win(vim.g.main_window)
  end

  vim.cmd('normal! `' .. mark_char)
  vim.cmd 'normal! zz'
end

local function show_fullscreen_popup_at_mark()
  local marklist_buf = vim.g.mark_window_buf
  if not marklist_buf or not vim.api.nvim_buf_is_valid(marklist_buf) then
    return
  end

  local line_num = vim.fn.line '.'
  local line_text = vim.fn.getline(line_num)

  local mark_char = line_text:match '├─ ([A-Z]):' or line_text:match '([a-z]):'

  if not mark_char then
    if vim.g.popup_win and vim.api.nvim_win_is_valid(vim.g.popup_win) then
      vim.api.nvim_win_close(vim.g.popup_win, true)
      vim.g.popup_win = nil
      vim.g.popup_buf = nil
      vim.g.current_mark = nil
    end
    return
  end

  if vim.g.current_mark == mark_char then
    return
  end
  vim.g.current_mark = mark_char

  local all_marks = Get_all_marks()
  local mark_info
  for _, m in ipairs(all_marks) do
    if m.mark == mark_char then
      mark_info = m
      break
    end
  end

  if not mark_info or not mark_info.filepath or mark_info.filepath == '' then
    return
  end

  local filepath = mark_info.filepath
  local target_line = mark_info.line

  local file_lines = {}
  local f = io.open(filepath, 'r')
  if not f then
    return
  end

  local index = 1
  for line in f:lines() do
    if index == target_line then
      table.insert(file_lines, '▶ ' .. line .. ' ◀◀◀')
    else
      table.insert(file_lines, '  ' .. line)
    end
    index = index + 1
  end
  f:close()

  if vim.g.popup_win and vim.api.nvim_win_is_valid(vim.g.popup_win) then
    vim.api.nvim_buf_set_lines(vim.g.popup_buf, 0, -1, false, file_lines)
    vim.api.nvim_win_set_cursor(vim.g.popup_win, { target_line, 2 }) -- Move cursor after the arrow
    vim.cmd 'normal! zz' -- Center cursor
    return
  end

  -- Save original window
  vim.g.original_win = vim.api.nvim_get_current_win()

  local popup_buf = vim.api.nvim_create_buf(false, true)
  Set_buf_filetype_by_ext(filepath, popup_buf)
  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, file_lines)

  local ft = vim.bo[popup_buf].filetype
  if ft and ft ~= '' then
    vim.api.nvim_buf_set_option(popup_buf, 'filetype', ft)
    vim.api.nvim_buf_set_option(popup_buf, 'syntax', ft)

    vim.cmd('doautocmd BufRead ' .. filepath)
    vim.cmd 'syntax enable'
  end

  local editor_width = vim.o.columns
  local editor_height = vim.o.lines
  local width = math.floor(editor_width * 4 / 5)
  local height = editor_height - 2
  local row = 1
  local col = 0

  local popup_win = vim.api.nvim_open_win(popup_buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'none',
  })

  vim.bo[popup_buf].buftype = 'nofile'
  vim.bo[popup_buf].bufhidden = 'wipe'
  vim.bo[popup_buf].swapfile = false
  vim.wo[popup_win].wrap = false
  vim.wo[popup_win].number = true
  vim.wo[popup_win].relativenumber = true

  local main_win = vim.g.original_win
  local main_buf = vim.api.nvim_win_get_buf(main_win)
  local main_ft = vim.bo[main_buf].filetype

  vim.bo[popup_buf].filetype = main_ft -- Apply the same filetype (syntax highlighting)
  vim.api.nvim_win_set_option(popup_win, 'winhl', 'Normal:Normal') -- Match background

  vim.api.nvim_win_set_cursor(popup_win, { target_line, 2 }) -- Move cursor after the arrow
  vim.cmd 'normal! zz' -- Center cursor

  vim.g.popup_win = popup_win
  vim.g.popup_buf = popup_buf
end

local function close_popup_on_leave()
  if vim.g.popup_win and vim.api.nvim_win_is_valid(vim.g.popup_win) then
    vim.api.nvim_win_close(vim.g.popup_win, true)
    vim.g.popup_win = nil
    vim.g.popup_buf = nil

    if vim.g.original_win and vim.api.nvim_win_is_valid(vim.g.original_win) then
      vim.api.nvim_set_current_win(vim.g.original_win)
    end
  end
end

local function toggle_mark_window()
  if not vim.g.mark_window_buf then
    vim.g.mark_window_buf = nil
  end
  if not vim.g.mark_window_win then
    vim.g.mark_window_win = nil
  end

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

  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = vim.g.mark_window_buf,
    callback = function()
      show_fullscreen_popup_at_mark()
      vim.api.nvim_set_current_win(vim.g.mark_window_win)
    end,
  })

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = vim.g.mark_window_buf,
    callback = function()
      close_popup_on_leave()
    end,
  })

  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].buftype = 'nofile'
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].wrap = false

  local all_marks = Get_all_marks()

  if #all_marks == 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'No global marks found' })
    return
  end

  local grouped_marks = {}
  for _, m in ipairs(all_marks) do
    local filename = m.filename
    if not grouped_marks[filename] then
      grouped_marks[filename] = {}
    end
    table.insert(grouped_marks[filename], m)
  end

  local lines = {}
  local filename_line_indices = {}

  local func_highlight_positions = {}

  for filename, marks in pairs(grouped_marks) do
    local filename_line_idx = #lines
    table.insert(lines, filename)
    table.sort(marks, function(a, b)
      return a.mark < b.mark
    end)

    for _, mark in ipairs(marks) do
      local display_text
      if mark.nearest_func then
        display_text = mark.nearest_func
      elseif mark.text then
        Set_buf_filetype_by_ext(filename, buf)
        display_text = mark.text
      else
        display_text = ''
      end

      -- local display_text = mark.nearest_func or mark.text or ''
      local line_text = string.format(' ├─ %s: %s', mark.mark, display_text)
      table.insert(lines, line_text)

      -- If nearest_func exists, store the highlight position
      if mark.nearest_func then
        local line_idx = #lines -- Line index after insertion
        local col_start = #string.format(' ├─ %s: ', mark.mark) -- Start after `mark.mark`
        local col_end = col_start + #mark.nearest_func

        -- Store the position for highlighting later
        table.insert(func_highlight_positions, { line_idx, col_start, col_end })
      end
    end
    filename_line_indices[#filename_line_indices + 1] = filename_line_idx
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_hl(0, 'FileHighlight', { fg = '#5097A4' })
  vim.api.nvim_set_hl(0, 'MarkHighlight', { fg = '#f1c232' })

  for _, line_idx in ipairs(filename_line_indices) do
    vim.api.nvim_buf_add_highlight(buf, -1, 'FileHighlight', line_idx, 0, -1)
  end
  for _, pos in ipairs(func_highlight_positions) do
    local line_idx, col_start, col_end = unpack(pos)
    vim.api.nvim_buf_add_highlight(buf, 0, '@function', line_idx - 1, col_start, col_end)
  end

  for line_idx, line in ipairs(lines) do
    local mark_match = line:match '├─%s([A-Za-z]):' -- Match both uppercase and lowercase marks
    if mark_match then
      local end_col = line:find(mark_match .. ':') -- Find exact position
      if end_col then
        vim.api.nvim_buf_add_highlight(buf, -1, 'MarkHighlight', line_idx - 1, end_col - 1, end_col)
      end
    end
  end

  vim.keymap.set('n', '<CR>', function()
    require('config.marklist').jump_to_mark()
  end, { noremap = true, silent = true, buffer = buf })
end

vim.keymap.set('n', '<leader>tm', toggle_mark_window, { desc = '[T]oggle [M]arklist' })

return {
  toggle_mark_window = toggle_mark_window,
  jump_to_mark = jump_to_mark,
}
