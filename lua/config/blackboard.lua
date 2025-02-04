local M = {}

require 'config.util_blackboard_preview'
require 'config.util_blackboard_mark_info'

---@class blackboard.Options
---@field show_nearest_func boolean
---field not_under_func_symbol string
---field under_func_symbol string
local options = {
  show_nearest_func = false,
  not_under_func_symbol = '🔥',
  under_func_symbol = '╰─',
}

--- Setup the plugin
---@param opts blackboard.Options
M.setup = function(opts)
  options = vim.tbl_deep_extend('force', options, opts or {})
end

---@class blackboard.State
---@field blackboard_win number
---@field blackboard_buf number
---@field popup_win number
---@field popup_buf number
---@field current_mark string
---@field original_win number
---@field original_buf number
---@field filepath_to_content_lines table<string, string[]>
---@field mark_to_line table<string, number>
local blackboard_state = {
  blackboard_win = -1,
  blackboard_buf = -1,
  popup_win = -1,
  popup_buf = -1,
  current_mark = '',
  original_win = -1,
  original_buf = -1,
  filepath_to_content_lines = {},
  mark_to_line = {},
}

---@param options blackboard.Options
local function load_all_file_contents(options)
  local all_accessible_marks = Get_accessible_marks_info(options)
  local grouped_marks_by_filepath = Group_marks_info_by_filepath(all_accessible_marks)
  local pp = require 'plenary.path'
  for filepath, _ in pairs(grouped_marks_by_filepath) do
    local data = pp:new(filepath):read()
    local content_lines = vim.split(data, '\n', { plain = true })
    blackboard_state.filepath_to_content_lines[filepath] = content_lines
  end
end

---@class blackboard.ParsedMarks
---@field blackboardLines string[]
---@field virtualLines table<number, blackboard.VirtualLine>

---@class blackboard.VirtualLine
---@field filename string
---@field func_name string

---@param marks_info blackboard.MarkInfo[]
---@return blackboard.ParsedMarks
local function parse_grouped_marks_info(marks_info)
  local grouped_marks_by_filename = Group_marks_info_by_filepath(marks_info)
  local blackboardLines = {}
  local virtualLines = {}
  local markToLine = {}

  for filepath, marks_info in pairs(grouped_marks_by_filename) do
    local filename = vim.fn.fnamemodify(filepath, ':t')
    table.sort(marks_info, function(a, b)
      return a.line < b.line
    end)

    if #blackboardLines == 0 then
      table.insert(blackboardLines, filename)
    end

    for _, mark_info in ipairs(marks_info) do
      local currentLine = #blackboardLines + 1
      virtualLines[currentLine] = {
        filename = filename,
        func_name = mark_info.nearest_func,
      }
      if mark_info.nearest_func then
        table.insert(blackboardLines, string.format('%s %s: %s', options.under_func_symbol, mark_info.mark, mark_info.text))
      else
        table.insert(blackboardLines, string.format('%s %s: %s', options.not_under_func_symbol, mark_info.mark, mark_info.text))
      end
      print('mark: ' .. mark_info.mark)
      print('currentLine: ' .. currentLine)
      blackboard_state.mark_to_line[mark_info.mark] = currentLine
    end
  end

  return {
    blackboardLines = blackboardLines,
    virtualLines = virtualLines,
  }
end

local function add_highlights(parsedMarks)
  local blackboardLines = parsedMarks.blackboardLines
  vim.api.nvim_set_hl(0, 'FileHighlight', { fg = '#5097A4' })
  vim.api.nvim_buf_add_highlight(blackboard_state.blackboard_buf, -1, 'FileHighlight', 0, 0, -1)

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
end

local function make_func_line(data)
  if not data.func_name or data.func_name == '' then
    return ''
  end
  return '❯ ' .. data.func_name
end

local function get_virtual_lines_no_func_lines(filename, last_seen_filename)
  if filename == last_seen_filename then
    return nil
  end
  return { { { '', '' } }, { { filename, 'FileHighlight' } } }
end

---@param options blackboard.Options
local function get_virtual_lines(filename, funcLine, last_seen_filename, last_seen_func, options)
  if not options.show_nearest_func or funcLine == '' then
    return get_virtual_lines_no_func_lines(filename, last_seen_filename)
  end
  if filename ~= last_seen_filename then
    return { { { '', '' } }, { { filename, 'FileHighlight' } }, { { funcLine, '@function' } } }
  end
  if funcLine ~= last_seen_func then
    return { { { '', '' } }, { { funcLine, '@function' } } }
  end
  return nil
end

---@param blackboard_state blackboard.State
---@param options blackboard.Options
local function add_virtual_lines(parsedMarks, blackboard_state, options)
  local ns_blackboard = vim.api.nvim_create_namespace 'blackboard_extmarks'
  local last_seen_filename = ''
  local last_seen_func = ''

  for lineNum, data in pairs(parsedMarks.virtualLines) do
    local filename = data.filename or ''
    local funcLine = make_func_line(data)
    local extmarkLine = lineNum - 1

    if extmarkLine == 1 then
      vim.api.nvim_buf_set_extmark(blackboard_state.blackboard_buf, ns_blackboard, 0, 0, {
        virt_lines = { { { filename, 'FileHighlight' } } },
        virt_lines_above = true,
        hl_mode = 'combine',
        priority = 10,
      })
    elseif extmarkLine > 1 then
      local virt_lines = get_virtual_lines(filename, funcLine, last_seen_filename, last_seen_func, options)
      if virt_lines then
        vim.api.nvim_buf_set_extmark(blackboard_state.blackboard_buf, ns_blackboard, extmarkLine, 0, {
          virt_lines = virt_lines,
          virt_lines_above = true,
          hl_mode = 'combine',
          priority = 10,
        })
      end
    end

    last_seen_filename = filename
    last_seen_func = funcLine
  end
end
---@param marks_info blackboard.MarkInfo[]
local function create_new_blackboard(marks_info, options)
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

  local marks_info = marks_info or Get_accessible_marks_info(options)
  local parsed_marks_info = parse_grouped_marks_info(marks_info)
  vim.api.nvim_buf_set_lines(blackboard_state.blackboard_buf, 0, -1, false, parsed_marks_info.blackboardLines)
  add_highlights(parsed_marks_info)
  add_virtual_lines(parsed_marks_info, blackboard_state, options)
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
    blackboard_state.filepath_to_content_lines = {}
    return
  end

  local marks_info = Get_accessible_marks_info(options)
  create_new_blackboard(marks_info, options)
  vim.api.nvim_set_current_win(blackboard_state.original_win)
  load_all_file_contents(options)
  Attach_autocmd_blackboard_buf(blackboard_state, marks_info)
end

M.toggle_mark_context = function()
  if not vim.api.nvim_win_is_valid(blackboard_state.blackboard_win) then
    return
  else
    vim.api.nvim_win_hide(blackboard_state.blackboard_win)
    vim.api.nvim_buf_delete(blackboard_state.blackboard_buf, { force = true })
    vim.api.nvim_del_augroup_by_name 'blackboard_group'
  end
  options.show_nearest_func = not options.show_nearest_func
  local marks_info = Get_accessible_marks_info(options)
  create_new_blackboard(marks_info, options)
  vim.api.nvim_set_current_win(blackboard_state.original_win)
  Attach_autocmd_blackboard_buf(blackboard_state, marks_info)
end

M.jump_to_mark = function(blackboard_state)
  local mark_char = Get_mark_char(blackboard_state)
  assert(vim.api.nvim_win_is_valid(blackboard_state.original_win), 'Invalid original window')
  vim.api.nvim_set_current_win(blackboard_state.original_win)
  vim.cmd('normal! `' .. mark_char)
  vim.cmd 'normal! zz'
end

vim.api.nvim_create_user_command('BlackboardToggle', M.toggle_mark_window, {
  desc = 'Toggle Blackboard',
})

vim.api.nvim_create_user_command('BlackboardToggleContext', M.toggle_mark_context, {
  desc = 'Toggle Mark Context',
})

local function preview_mark(mark)
  local line = blackboard_state.mark_to_line[mark]
  if not line then
    print('Mark not found on blackboard: ' .. mark)
    return
  end
  vim.api.nvim_set_current_win(blackboard_state.blackboard_win)
  vim.api.nvim_win_set_cursor(blackboard_state.blackboard_win, { line, 0 })
end

vim.api.nvim_create_user_command('BlackboardPreviewMark', function(opts)
  local mark = opts.fargs[1]
  preview_mark(mark)
end, { nargs = '*' })

return M
