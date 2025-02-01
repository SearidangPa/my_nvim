require 'config.util_find_func'
require 'config.util_marklist'
require 'config.util_highlight'
local plenary_filetype = require 'plenary.filetype'

local original_win = -1
local blackboard_win, blackboard_buf = -1, -1
local popup_win, popup_buf = -1, -1
local current_mark

local function get_mark_char()
  if not vim.api.nvim_buf_is_valid(blackboard_buf) then
    vim.notify('blackboard buffer is invalid', vim.log.levels.ERROR)
    return
  end
  local line_num = vim.fn.line '.'
  local line_text = vim.fn.getline(line_num)

  local mark_char = line_text:match '([A-Z]):' or line_text:match '([a-z]):'
  assert(mark_char, 'No mark character found')
  return mark_char
end

local function jump_to_mark()
  local mark_char = get_mark_char()

  if not vim.api.nvim_win_is_valid(original_win) then
    print 'Invalid original window'
    return
  end

  vim.api.nvim_set_current_win(original_win)
  vim.cmd('normal! `' .. mark_char)
  vim.cmd 'normal! zz'
end

local function retrieve_mark_info(mark_char)
  local all_marks = Get_accessible_marks_info()
  local mark_info
  for _, m in ipairs(all_marks) do
    if m.mark == mark_char then
      mark_info = m
      break
    end
  end

  assert(mark_info, 'No mark info found for mark: ' .. mark_char)
  assert(mark_info.filepath and mark_info.filepath ~= '', 'No filepath found for mark: ' .. mark_char)
  return mark_info
end

local function show_fullscreen_popup_at_mark()
  local mark_char = get_mark_char()
  if current_mark == mark_char then
    return
  end
  current_mark = mark_char

  local mark_info = retrieve_mark_info(mark_char)

  local filepath = mark_info.filepath
  local target_line = mark_info.line

  local fp_bufnr = vim.fn.bufnr(filepath)
  if not vim.api.nvim_buf_is_valid(fp_bufnr) then
    print('Invalid buffer for file:', filepath)
    return
  end

  if vim.g.popup_win and vim.api.nvim_win_is_valid(vim.g.popup_win) then
    local line_count = vim.api.nvim_buf_line_count(vim.g.popup_buf)
    if target_line >= line_count then
      target_line = line_count
    end
    TransferBuf(fp_bufnr, vim.g.popup_buf)
    vim.api.nvim_win_set_cursor(vim.g.popup_win, { target_line, 2 }) -- Move cursor after the arrow
  end

  local popup_buf = vim.api.nvim_create_buf(false, true)
  TransferBuf(fp_bufnr, popup_buf)
  -- vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, file_lines)

  local filetype = plenary_filetype.detect_from_extension(filepath)

  local lang = vim.treesitter.language.get_lang(filetype)
  if not pcall(vim.treesitter.start, popup_buf, lang) then
    vim.bo[popup_buf].syntax = filetype
  end

  local editor_width = vim.o.columns
  local editor_height = vim.o.lines
  local width = math.floor(editor_width * 4 / 5)
  local height = editor_height - 3
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
  vim.api.nvim_set_option_value('winhl', 'Normal:Normal', { win = popup_win }) -- Match background

  vim.g.popup_win = popup_win
  vim.g.popup_buf = popup_buf

  vim.api.nvim_win_set_cursor(vim.g.popup_win, { target_line, 2 }) -- Move cursor after the arrow
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

local function create_buf_autocmds(bufnr, win)
  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = bufnr,
    callback = function()
      show_fullscreen_popup_at_mark()
      vim.api.nvim_set_current_win(win)
    end,
  })

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = bufnr,
    callback = function()
      close_popup_on_leave()
    end,
  })

  vim.keymap.set('n', '<CR>', function()
    require('config.marklist').jump_to_mark()
  end, { noremap = true, silent = true, buffer = blackboard_buf })
end

local function create_new_blackboard(blackboard_buf)
  vim.cmd 'vsplit'
  blackboard_win = vim.api.nvim_get_current_win()
  if not vim.api.nvim_buf_is_valid(blackboard_buf) then
    blackboard_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[blackboard_buf].bufhidden = 'wipe'
    vim.bo[blackboard_buf].buftype = 'nofile'
    vim.bo[blackboard_buf].swapfile = false
  end

  vim.api.nvim_win_set_width(blackboard_win, math.floor(vim.o.columns / 5))
  vim.api.nvim_win_set_buf(blackboard_win, blackboard_buf)
  vim.wo[blackboard_win].number = false
  vim.wo[blackboard_win].relativenumber = false
  vim.wo[blackboard_win].wrap = false
  return blackboard_buf, blackboard_win
end

local function group_marks_by_file()
  local all_accessible_marks = Get_accessible_marks_info()
  print(vim.inspect(all_accessible_marks))
  local grouped_marks = {}
  for _, m in ipairs(all_accessible_marks) do
    local filename = m.filename
    if not grouped_marks[filename] then
      grouped_marks[filename] = {}
    end
    table.insert(grouped_marks[filename], m)
  end
  return grouped_marks
end

local function toggle_mark_window()
  original_win = vim.api.nvim_get_current_win()

  if vim.api.nvim_win_is_valid(blackboard_win) then
    vim.api.nvim_win_hide(blackboard_win)
    blackboard_buf = -1
    return
  end

  blackboard_buf, blackboard_win = create_new_blackboard(blackboard_buf)
  create_buf_autocmds(blackboard_buf, blackboard_win)

  local grouped_marks = group_marks_by_file()
  local blackboard_lines = {}
  local filename_line_indices = {}
  local func_highlight_positions = {}

  for filename, marks in pairs(grouped_marks) do
    local filename_line_idx = #blackboard_lines
    table.insert(blackboard_lines, filename)
    table.sort(marks, function(a, b)
      return a.mark < b.mark
    end)

    for _, mark in ipairs(marks) do
      local display_text
      if mark.nearest_func then
        display_text = mark.nearest_func
      elseif mark.text then
        local filetype = plenary_filetype.detect_from_extension(filename)
        vim.bo[blackboard_buf].filetype = filetype
        display_text = vim.trim(mark.text)
      else
        display_text = ''
      end

      local line_text = string.format(' ├─ %s: %s', mark.mark, display_text)
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

  vim.api.nvim_buf_set_lines(blackboard_buf, 0, -1, false, blackboard_lines)
  vim.api.nvim_set_hl(0, 'FileHighlight', { fg = '#5097A4' })
  vim.api.nvim_set_hl(0, 'MarkHighlight', { fg = '#f1c232' })

  for _, line_idx in ipairs(filename_line_indices) do
    vim.api.nvim_buf_add_highlight(blackboard_buf, -1, 'FileHighlight', line_idx, 0, -1)
  end
  for _, pos in ipairs(func_highlight_positions) do
    local line_idx, col_start, col_end = unpack(pos)
    vim.api.nvim_buf_add_highlight(blackboard_buf, 0, '@function', line_idx - 1, col_start, col_end)
  end

  for line_idx, line in ipairs(blackboard_lines) do
    local mark_match = line:match '├─%s([A-Za-z]):' -- Match both uppercase and lowercase marks
    if mark_match then
      local end_col = line:find(mark_match .. ':') -- Find exact position
      if end_col then
        vim.api.nvim_buf_add_highlight(blackboard_buf, -1, 'MarkHighlight', line_idx - 1, end_col - 1, end_col)
      end
    end
  end

  vim.api.nvim_set_current_win(original_win)
end

vim.keymap.set('n', '<leader>tm', toggle_mark_window, { desc = '[T]oggle [M]arklist' })

return {
  toggle_mark_window = toggle_mark_window,
  jump_to_mark = jump_to_mark,
}
