local M = {}

require 'config.util_blackboard_preview'
require 'config.util_blackboard_mark_info'
require 'config.util_blackboard_context'

local blackboard_state = {
  blackboard_win = -1,
  blackboard_buf = -1,
  popup_win = -1,
  popup_buf = -1,
  current_mark = nil,
  original_win = -1,
  original_buf = -1,
  show_context = false,
}

local filepath_to_content_lines = {}

local function load_all_file_contents()
  local grouped_marks_by_filepath = Group_marks_info_by_filepath()
  local pp = require 'plenary.path'
  for filepath, _ in pairs(grouped_marks_by_filepath) do
    local data = pp:new(filepath):read()
    local content_lines = vim.split(data, '\n', { plain = true })
    filepath_to_content_lines[filepath] = content_lines
  end
end

---@param marks_info table
---@param opts table
---@return table
local function parse_grouped_marks_info(marks_info, opts)
  local grouped_marks_by_filename = Group_marks_info_by_file(marks_info)
  local blackboardLines = {}
  local virtualLines = {}

  local show_context = opts.show_context
  local symbol = opts.show_context and '╰─' or '🔥'

  for filename, marks_info in pairs(grouped_marks_by_filename) do
    table.sort(marks_info, function(a, b)
      return a.mark < b.mark
    end)

    if #blackboardLines == 0 and opts.show_context then
      table.insert(blackboardLines, filename)
    end

    for _, mark_info in ipairs(marks_info) do
      local currentLine = #blackboardLines + 1
      virtualLines[currentLine] = {
        filename = filename,
        func_name = mark_info.nearest_func,
      }
      if mark_info.nearest_func then
        table.insert(blackboardLines, string.format('%s %s: %s', symbol, mark_info.mark, mark_info.text))
      else
        table.insert(blackboardLines, string.format('🔥 %s: %s', mark_info.mark, mark_info.text))
      end
    end
  end

  return {
    blackboardLines = blackboardLines,
    virtualLines = virtualLines,
  }
end

---@param opts table
---@param parsedMarks table
local function add_highlights(opts, parsedMarks)
  local blackboardLines = parsedMarks.blackboardLines

  vim.api.nvim_set_hl(0, 'MarkHighlight', { fg = '#f1c232' })
  for lineIdx, line in ipairs(blackboardLines) do
    local markMatch = line:match '([A-Za-z]):'
    if markMatch then
      local endCol = line:find(markMatch .. ':')
      if endCol then
        vim.api.nvim_buf_add_highlight(blackboard_state.blackboard_buf, -1, 'MarkHighlight', lineIdx - 1, endCol - 1, endCol)
      end
    end
  end
  if opts.show_context then
    vim.api.nvim_buf_add_highlight(blackboard_state.blackboard_buf, -1, 'FileHighlight', 0, 0, -1)
  end
end

---@param opts table
local function create_new_blackboard(opts)
  vim.cmd 'vsplit'
  blackboard_state.blackboard_win = vim.api.nvim_get_current_win()
  local plenary_filetype = require 'plenary.filetype'
  local filetype = plenary_filetype.detect(vim.api.nvim_buf_get_name(0))

  if not vim.api.nvim_buf_is_valid(blackboard_state.blackboard_buf) then
    blackboard_state.blackboard_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[blackboard_state.blackboard_buf].bufhidden = 'hide'
    vim.bo[blackboard_state.blackboard_buf].buftype = 'nofile'
    vim.bo[blackboard_state.blackboard_buf].buflisted = false
    vim.bo[blackboard_state.blackboard_buf].swapfile = false
    vim.bo[blackboard_state.blackboard_buf].filetype = filetype
  end

  local marks_info = opts.marks_info or Get_accessible_marks_info()
  local parsedMarks = parse_grouped_marks_info(marks_info, opts)
  vim.api.nvim_buf_set_lines(blackboard_state.blackboard_buf, 0, -1, false, parsedMarks.blackboardLines)
  if opts.show_context then
    Add_virtual_lines(parsedMarks, blackboard_state)
  end
  add_highlights(opts, parsedMarks)
  vim.api.nvim_win_set_buf(blackboard_state.blackboard_win, blackboard_state.blackboard_buf)

  vim.api.nvim_win_set_width(blackboard_state.blackboard_win, math.floor(vim.o.columns / 4))
  vim.wo[blackboard_state.blackboard_win].number = false
  vim.wo[blackboard_state.blackboard_win].relativenumber = false
  vim.wo[blackboard_state.blackboard_win].wrap = false
end

M.toggle_mark_window = function()
  blackboard_state.original_win = vim.api.nvim_get_current_win()
  blackboard_state.original_buf = vim.api.nvim_get_current_buf()

  if vim.api.nvim_win_is_valid(blackboard_state.blackboard_win) then
    vim.api.nvim_win_hide(blackboard_state.blackboard_win)
    vim.api.nvim_buf_delete(blackboard_state.blackboard_buf, { force = true })
    vim.api.nvim_del_augroup_by_name 'blackboard_group'
    filepath_to_content_lines = {}
    return
  end

  local marks_info = Get_accessible_marks_info()
  create_new_blackboard { marks_info = marks_info, show_context = false }
  vim.api.nvim_set_current_win(blackboard_state.original_win)
  load_all_file_contents()
  Attach_autocmd_blackboard_buf(blackboard_state, marks_info, filepath_to_content_lines)
end

M.toggle_mark_context = function()
  if not vim.api.nvim_win_is_valid(blackboard_state.blackboard_win) then
    return
  else
    vim.api.nvim_win_hide(blackboard_state.blackboard_win)
    vim.api.nvim_buf_delete(blackboard_state.blackboard_buf, { force = true })
    vim.api.nvim_del_augroup_by_name 'blackboard_group'
  end
  local marks_info = Get_accessible_marks_info()
  blackboard_state.show_context = not blackboard_state.show_context
  create_new_blackboard { marks_info = Get_accessible_marks_info(), show_context = blackboard_state.show_context }
  vim.api.nvim_set_current_win(blackboard_state.original_win)
  Attach_autocmd_blackboard_buf(blackboard_state, marks_info, filepath_to_content_lines)
end

vim.api.nvim_create_user_command('ToggleBlackboard', M.toggle_mark_window, {
  desc = 'Toggle Blackboard',
})

vim.api.nvim_create_user_command('ToggleMarkContext', M.toggle_mark_context, {
  desc = 'Toggle Mark Context',
})

M.jump_to_mark = function(blackboard_state)
  local mark_char = Get_mark_char(blackboard_state)
  assert(vim.api.nvim_win_is_valid(blackboard_state.original_win), 'Invalid original window')
  vim.api.nvim_set_current_win(blackboard_state.original_win)
  vim.cmd('normal! `' .. mark_char)
  vim.cmd 'normal! zz'
end

return M
