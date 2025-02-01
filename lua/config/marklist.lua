require 'config.util_find_func'
require 'config.util_highlight'
local plenary_filetype = require 'plenary.filetype'

local blackboard_state = {
  blackboard_win = -1,
  blackboard_buf = -1,
  popup_win = -1,
  popup_buf = -1,
  current_mark = nil,
  original_win = -1,
}

-- lifted from nvim-bqf
local api = vim.api
local fn = vim.fn
local cmd = vim.cmd
function TransferBuf(from, to)
  local function transferFile(rb, wb)
    local ePath = fn.fnameescape(api.nvim_buf_get_name(rb))
    local ok, msg = pcall(api.nvim_buf_call, wb, function()
      cmd(([[ noa call deletebufline(%d, 1, '$') ]]):format(wb))
      cmd(([[ noa sil 0read %s ]]):format(ePath))
      cmd(([[ noa call deletebufline(%d, '$') ]]):format(wb))
    end)
    return ok, msg
  end

  local fromLoaded = api.nvim_buf_is_loaded(from)
  if fromLoaded then
    if vim.bo[from].modified then
      local lines = api.nvim_buf_get_lines(from, 0, -1, false)
      api.nvim_buf_set_lines(to, 0, -1, false, lines)
    else
      if not transferFile(from, to) then
        local lines = api.nvim_buf_get_lines(from, 0, -1, false)
        api.nvim_buf_set_lines(to, 0, -1, false, lines)
      end
    end
  else
    local ok, msg = transferFile(from, to)
    if not ok and msg:match [[:E484: Can't open file]] then
      cmd(('noa call bufload(%d)'):format(from))
      local lines = api.nvim_buf_get_lines(from, 0, -1, false)
      cmd(('noa bun %d'):format(from))
      api.nvim_buf_set_lines(to, 0, -1, false, lines)
    end
  end
  vim.bo[to].modified = false
end

local function add_mark_info(marks_info, mark, bufnr, line, col)
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- for tree-sitter
  local filetype = plenary_filetype.detect_from_extension(filepath)
  vim.bo[bufnr].filetype = filetype

  local nearest_func = Nearest_function_at_line(bufnr, line)
  local text
  if not nearest_func then
    text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
  end

  local filename = vim.fn.fnamemodify(filepath, ':t')
  table.insert(marks_info, {
    mark = mark,
    bufnr = bufnr,
    filename = filename,
    filepath = filepath,
    filetype = filetype,
    line = line,
    col = col,
    nearest_func = nearest_func,
    text = text,
  })
end

local function add_local_marks(marks_info)
  local mark_list = vim.fn.getmarklist(0)

  for _, mark_entry in ipairs(mark_list) do
    local mark = mark_entry.mark:sub(2, 2)
    if mark:match '[a-z]' then
      local bufnr = mark_entry.pos[1]
      local line = mark_entry.pos[2]
      local col = mark_entry.pos[3]

      if vim.api.nvim_buf_is_valid(bufnr) then
        add_mark_info(marks_info, mark, bufnr, line, col)
      end
    end
  end
end

--- @param marks_info table
--- @param char number
--- @param cwd string
local function add_global_mark_info(marks_info, char, cwd)
  local mark = string.char(char)
  local pos = vim.fn.getpos("'" .. mark)
  if pos[1] == 0 then
    return
  end
  local bufnr = pos[1]
  local line = pos[2]
  local col = pos[3]

  local filepath = vim.fn.bufname(bufnr)
  local abs_filepath = vim.fn.fnamemodify(filepath, ':p')

  if not abs_filepath:find(cwd, 1, true) then
    return
  end
  add_mark_info(marks_info, mark, bufnr, line, col)
end

local function get_accessible_marks_info()
  local marks_info = {}
  local cwd = vim.fn.getcwd()
  for char = string.byte 'A', string.byte 'Z' do
    add_global_mark_info(marks_info, char, cwd)
  end
  add_local_marks(marks_info)

  return marks_info
end

local function get_mark_char(blackboard_buf)
  if not vim.api.nvim_buf_is_valid(blackboard_buf) then
    vim.notify('blackboard buffer is invalid', vim.log.levels.ERROR)
    return
  end
  local line_num = vim.fn.line '.'
  local line_text = vim.fn.getline(line_num)

  local mark_char = line_text:match '([A-Z]):' or line_text:match '([a-z]):'
  return mark_char
end

local function jump_to_mark()
  local mark_char = get_mark_char(blackboard_state.blackboard_buf)

  if not vim.api.nvim_win_is_valid(blackboard_state.original_win) then
    print 'Invalid original window'
    return
  end

  vim.api.nvim_set_current_win(blackboard_state.original_win)
  vim.cmd('normal! `' .. mark_char)
  vim.cmd 'normal! zz'
end

local function retrieve_mark_info(mark_char)
  local all_marks = get_accessible_marks_info()
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

local function set_cursor_for_popup_win(target_line)
  local line_count = vim.api.nvim_buf_line_count(blackboard_state.popup_buf)
  if target_line >= line_count then
    target_line = line_count
  end
  vim.api.nvim_win_set_cursor(blackboard_state.popup_win, { target_line, 2 }) -- Move cursor after the arrow
end

local function open_popup_win(mark_info)
  local filetype = mark_info.filetype
  local lang = vim.treesitter.language.get_lang(filetype)
  if not pcall(vim.treesitter.start, blackboard_state.popup_buf, lang) then
    vim.bo[blackboard_state.popup_buf].syntax = filetype
  end

  local editor_width = vim.o.columns
  local editor_height = vim.o.lines
  local width = math.floor(editor_width * 4 / 5)
  local height = editor_height - 3
  local row = 1
  local col = 0

  blackboard_state.popup_win = vim.api.nvim_open_win(blackboard_state.popup_buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'none',
  })

  vim.bo[blackboard_state.popup_buf].buftype = 'nofile'
  vim.bo[blackboard_state.popup_buf].bufhidden = 'wipe'
  vim.bo[blackboard_state.popup_buf].swapfile = false
  vim.bo[blackboard_state.popup_buf].filetype = mark_info.filetype
  vim.wo[blackboard_state.popup_win].wrap = false
  vim.wo[blackboard_state.popup_win].number = true
  vim.wo[blackboard_state.popup_win].relativenumber = true
  vim.api.nvim_set_option_value('winhl', 'Normal:Normal', { win = blackboard_state.popup_win }) -- Match background
end

local function show_fullscreen_popup_at_mark()
  local mark_char = get_mark_char(blackboard_state.blackboard_buf)
  if not mark_char then
    return
  end
  if blackboard_state.current_mark == mark_char then
    return
  end
  blackboard_state.current_mark = mark_char
  print('Showing popup for mark:', blackboard_state.current_mark)

  local mark_info = retrieve_mark_info(mark_char)
  local filepath = mark_info.filepath
  local target_line = mark_info.line
  local filepath_bufnr = mark_info.bufnr
  assert(vim.api.nvim_buf_is_valid(filepath_bufnr), 'Invalid buffer for file: ' .. filepath)

  if vim.api.nvim_win_is_valid(blackboard_state.popup_win) then
    TransferBuf(filepath_bufnr, blackboard_state.popup_buf)
    set_cursor_for_popup_win(target_line)
    return
  end

  blackboard_state.popup_buf = vim.api.nvim_create_buf(false, true)
  TransferBuf(filepath_bufnr, blackboard_state.popup_buf)
  open_popup_win(mark_info)
  set_cursor_for_popup_win(target_line)
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

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = blackboard_state.original_win,
    callback = function()
      blackboard_state.original_win = vim.api.nvim_get_current_win()
    end,
  })

  vim.keymap.set('n', '<CR>', function()
    require('config.marklist').jump_to_mark(blackboard_state.blackboard_buf)
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

local function group_marks_by_file()
  local all_accessible_marks = get_accessible_marks_info()
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

local function get_display_info(mark, filename)
  if mark.nearest_func then
    return mark.nearest_func
  end

  if mark.text then
    -- Set filetype for syntax highlighting
    local filetype = plenary_filetype.detect_from_extension(filename)
    vim.bo[blackboard_state.blackboard_buf].filetype = filetype
    return vim.trim(mark.text)
  end

  return ''
end

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
      local display_info = get_display_info(mark, filename)
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

  local grouped_marks = group_marks_by_file()
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
