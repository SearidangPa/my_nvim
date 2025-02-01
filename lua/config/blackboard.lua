require 'config.util_find_func'
require 'config.util_highlight'
require 'config.util_preview_blackboard'
require 'config.util_mark_info'
local plenary_filetype = require 'plenary.filetype'

local blackboard_state = {
  blackboard_win = -1,
  blackboard_buf = -1,
  popup_win = -1,
  popup_buf = -1,
  current_mark = nil,
  original_win = -1,
}

local function jump_to_mark()
  local mark_char = Get_mark_char(blackboard_state)
  assert(vim.api.nvim_win_is_valid(blackboard_state.original_win), 'Invalid original window')
  vim.api.nvim_set_current_win(blackboard_state.original_win)
  vim.cmd('normal! `' .. mark_char)
  vim.cmd 'normal! zz'
end

local function set_cursor_for_popup_win(target_line, mark_char)
  local line_count = vim.api.nvim_buf_line_count(blackboard_state.popup_buf)
  if target_line >= line_count then
    target_line = line_count
  end
  vim.api.nvim_win_set_cursor(blackboard_state.popup_win, { target_line, 2 }) -- Move cursor after the arrow

  vim.fn.sign_define('MySign', { text = mark_char, texthl = 'DiagnosticInfo' })
  vim.fn.sign_place(0, 'MySignGroup', 'MySign', blackboard_state.popup_buf, { lnum = target_line, priority = 100 })
end

local function show_fullscreen_popup_at_mark()
  local mark_char = Get_mark_char(blackboard_state)
  if not mark_char then
    return
  end
  if blackboard_state.current_mark == mark_char then
    return
  end
  blackboard_state.current_mark = mark_char

  local mark_info = Retrieve_mark_info(mark_char)
  local target_line = mark_info.line
  local filepath_bufnr = mark_info.bufnr

  if vim.api.nvim_win_is_valid(blackboard_state.popup_win) then
    TransferBuf(filepath_bufnr, blackboard_state.popup_buf)
    set_cursor_for_popup_win(target_line, mark_char)
    return
  end

  blackboard_state.popup_buf = vim.api.nvim_create_buf(false, true)
  TransferBuf(filepath_bufnr, blackboard_state.popup_buf)
  Open_popup_win(mark_info)
  set_cursor_for_popup_win(target_line, mark_char)
end

local function close_popup_on_leave()
  if vim.api.nvim_get_current_win() == blackboard_state.popup_win then
    return
  end

  if vim.api.nvim_win_is_valid(blackboard_state.popup_win) then
    vim.api.nvim_win_close(blackboard_state.popup_win, true)

    if vim.api.nvim_win_is_valid(blackboard_state.original_win) then
      vim.api.nvim_set_current_win(blackboard_state.original_win)
    end
  end
end

local function create_buf_autocmds(blackboard_state)
  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = blackboard_state.blackboard_buf,
    callback = function()
      show_fullscreen_popup_at_mark()
      vim.api.nvim_set_current_win(blackboard_state.blackboard_win)
    end,
  })

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = blackboard_state.blackboard_buf,
    callback = function()
      close_popup_on_leave()
    end,
  })

  vim.keymap.set('n', '<CR>', function()
    require('config.blackboard').jump_to_mark(blackboard_state.blackboard_buf)
  end, { noremap = true, silent = true, buffer = blackboard_state.blackboard_buf })
end

local function create_new_blackboard()
  vim.cmd 'vsplit'
  blackboard_state.blackboard_win = vim.api.nvim_get_current_win()

  if not vim.api.nvim_buf_is_valid(blackboard_state.blackboard_buf) then
    blackboard_state.blackboard_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[blackboard_state.blackboard_buf].bufhidden = 'wipe'
    vim.bo[blackboard_state.blackboard_buf].buftype = 'nofile'
    vim.bo[blackboard_state.blackboard_buf].swapfile = false
  end

  vim.api.nvim_win_set_width(blackboard_state.blackboard_win, math.floor(vim.o.columns / 5))
  vim.api.nvim_win_set_buf(blackboard_state.blackboard_win, blackboard_state.blackboard_buf)
  vim.wo[blackboard_state.blackboard_win].number = false
  vim.wo[blackboard_state.blackboard_win].relativenumber = false
  vim.wo[blackboard_state.blackboard_win].wrap = false
end

---@param grouped_marks table<string, table>
---@return table
local function parse_grouped_marks_info(grouped_marks)
  local blackboard_lines = {}
  local func_highlight_positions = {}
  local filename_line_indices = {}
  for filename, marks in pairs(grouped_marks) do
    local filename_line_idx = #blackboard_lines
    table.insert(blackboard_lines, filename)

    table.sort(marks, function(a, b)
      return a.mark < b.mark
    end)

    for _, mark in ipairs(marks) do
      local display_info = Get_display_info(blackboard_state, mark, filename)
      local line_text = string.format(' ├─ %s: %s', mark.mark, display_info)
      table.insert(blackboard_lines, line_text)

      if mark.nearest_func then
        local line_idx = #blackboard_lines
        local col_start = #string.format(' ├─ %s: ', mark.mark)
        local col_end = col_start + #mark.nearest_func
        table.insert(func_highlight_positions, { line_idx, col_start, col_end })
      end
    end

    filename_line_indices[#filename_line_indices + 1] = filename_line_idx
  end

  return {
    blackboard_lines = blackboard_lines,
    func_highlight_positions = func_highlight_positions,
    filename_line_indices = filename_line_indices,
  }
end

local function add_highlights(parsed_marks)
  local blackboard_lines = parsed_marks.blackboard_lines
  local func_highlight_positions = parsed_marks.func_highlight_positions
  local filename_line_indices = parsed_marks.filename_line_indices

  vim.api.nvim_set_hl(0, 'FileHighlight', { fg = '#5097A4' })
  for _, line_idx in ipairs(filename_line_indices) do
    vim.api.nvim_buf_add_highlight(blackboard_state.blackboard_buf, -1, 'FileHighlight', line_idx, 0, -1)
  end

  -- Highlight the function names
  for _, pos in ipairs(func_highlight_positions) do
    local line_idx, col_start, col_end = unpack(pos)
    vim.api.nvim_buf_add_highlight(blackboard_state.blackboard_buf, 0, '@function', line_idx - 1, col_start, col_end)
  end

  vim.api.nvim_set_hl(0, 'MarkHighlight', { fg = '#f1c232' })
  for line_idx, line in ipairs(blackboard_lines) do
    local mark_match = line:match '├─%s([A-Za-z]):'
    if mark_match then
      local end_col = line:find(mark_match .. ':')
      if end_col then
        vim.api.nvim_buf_add_highlight(blackboard_state.blackboard_buf, -1, 'MarkHighlight', line_idx - 1, end_col - 1, end_col)
      end
    end
  end
end

local function toggle_mark_window()
  blackboard_state.original_win = vim.api.nvim_get_current_win()

  if vim.api.nvim_win_is_valid(blackboard_state.blackboard_win) then
    vim.api.nvim_win_hide(blackboard_state.blackboard_win)
    return
  end

  create_new_blackboard()
  create_buf_autocmds(blackboard_state)

  local grouped_marks = Group_marks_info_by_file()
  local parsed_marks = parse_grouped_marks_info(grouped_marks)
  vim.api.nvim_buf_set_lines(blackboard_state.blackboard_buf, 0, -1, false, parsed_marks.blackboard_lines)
  add_highlights(parsed_marks)

  vim.api.nvim_set_current_win(blackboard_state.original_win)
end

vim.keymap.set('n', '<leader>tm', toggle_mark_window, { desc = '[T]oggle [M]arklist' })

return {
  toggle_mark_window = toggle_mark_window,
  jump_to_mark = jump_to_mark,
}
