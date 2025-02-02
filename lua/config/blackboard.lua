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
  original_buf = -1,
}

local filepath_to_content_lines = {}

local function create_new_blackboard()
  vim.cmd 'vsplit'
  blackboard_state.blackboard_win = vim.api.nvim_get_current_win()
  local filetype = plenary_filetype.detect(vim.api.nvim_buf_get_name(0))

  if not vim.api.nvim_buf_is_valid(blackboard_state.blackboard_buf) then
    blackboard_state.blackboard_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[blackboard_state.blackboard_buf].bufhidden = 'hide'
    vim.bo[blackboard_state.blackboard_buf].buftype = 'nofile'
    vim.bo[blackboard_state.blackboard_buf].buflisted = false
    vim.bo[blackboard_state.blackboard_buf].swapfile = false
    vim.bo[blackboard_state.blackboard_buf].filetype = filetype
  end

  vim.api.nvim_win_set_width(blackboard_state.blackboard_win, math.floor(vim.o.columns / 4))
  vim.api.nvim_win_set_buf(blackboard_state.blackboard_win, blackboard_state.blackboard_buf)
  vim.wo[blackboard_state.blackboard_win].number = false
  vim.wo[blackboard_state.blackboard_win].relativenumber = false
  vim.wo[blackboard_state.blackboard_win].wrap = false
end

local function load_all_file_contents()
  local grouped_marks_by_filepath = Group_marks_info_by_filepath()
  local pp = require 'plenary.path'
  for filepath, _ in pairs(grouped_marks_by_filepath) do
    local data = pp:new(filepath):read()
    filepath_to_content_lines[filepath] = vim.split(data, '\n', true)
  end
end

---@param opts table
---@return table
local function parse_grouped_marks_info(opts)
  local grouped_marks_by_filename = Group_marks_info_by_file()
  local blackboardLines = {}
  local virtualLines = {}

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
        table.insert(blackboardLines, string.format('╰─ %s: %s', mark_info.mark, mark_info.text))
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

---@param data table
local function make_func_line(data)
  if not data.func_name then
    return ''
  end
  return '❯ ' .. data.func_name
end

---@param filename string
---@param funcLine string
---@param last_seen_filename string
---@param last_seen_func string
---@return table | nil
local function get_virtual_lines(filename, funcLine, last_seen_filename, last_seen_func)
  if funcLine == '' then
    if filename == last_seen_filename then
      return nil
    end
    return { { { '', '' } }, { { filename, 'FileHighlight' } } }
  end

  if filename == last_seen_filename then
    if funcLine == last_seen_func then
      return nil
    end

    return { { { funcLine, '@function' } } }
  end

  if funcLine == last_seen_func then
    return { { { '', '' } }, { { filename, 'FileHighlight' } } }
  end
  return { { { '', '' } }, { { filename, 'FileHighlight' } }, { { funcLine, '@function' } } }
end

---@param parsedMarks table
local function add_virtual_lines(parsedMarks)
  local ns_blackboard = vim.api.nvim_create_namespace 'blackboard_extmarks'
  vim.api.nvim_set_hl(0, 'FileHighlight', { fg = '#5097A4' })
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
      local virt_lines = get_virtual_lines(filename, funcLine, last_seen_filename, last_seen_func)
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

---@param opts table: Table with optional keys
---     - show_context (bool, default=false): show context around the mark
local function toggle_mark_window(opts)
  opts = opts or {}
  opts.show_context = opts.show_context or false
  blackboard_state.original_win = vim.api.nvim_get_current_win()
  blackboard_state.original_buf = vim.api.nvim_get_current_buf()

  if vim.api.nvim_win_is_valid(blackboard_state.blackboard_win) then
    vim.api.nvim_win_hide(blackboard_state.blackboard_win)
    vim.api.nvim_buf_delete(blackboard_state.blackboard_buf, { force = true })
    vim.api.nvim_del_augroup_by_name 'blackboard_group'
    return
  end

  create_new_blackboard()
  local parsedMarks = parse_grouped_marks_info(opts)
  add_highlights(opts, parsedMarks)
  if opts.show_context then
    add_virtual_lines(parsedMarks)
  end
  vim.api.nvim_buf_set_lines(blackboard_state.blackboard_buf, 0, -1, false, parsedMarks.blackboardLines)
  vim.api.nvim_set_current_win(blackboard_state.original_win)

  load_all_file_contents()
  Create_autocmd(blackboard_state, filepath_to_content_lines)
end

vim.keymap.set('n', '<leader>tm', toggle_mark_window, { desc = '[T]oggle [M]arklist' })

return {
  toggle_mark_window = toggle_mark_window,
  Jump_to_mark = Jump_to_mark,
}
