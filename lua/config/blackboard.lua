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

---@param blackboard_state table
local function jump_to_mark(blackboard_state)
  local mark_char = Get_mark_char(blackboard_state)
  assert(vim.api.nvim_win_is_valid(blackboard_state.original_win), 'Invalid original window')
  vim.api.nvim_set_current_win(blackboard_state.original_win)
  vim.cmd('normal! `' .. mark_char)
  vim.cmd 'normal! zz'
end

local function create_new_blackboard()
  vim.cmd 'vsplit'
  blackboard_state.blackboard_win = vim.api.nvim_get_current_win()

  if not vim.api.nvim_buf_is_valid(blackboard_state.blackboard_buf) then
    blackboard_state.blackboard_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[blackboard_state.blackboard_buf].bufhidden = 'hide'
    vim.bo[blackboard_state.blackboard_buf].buftype = 'nofile'
    vim.bo[blackboard_state.blackboard_buf].buflisted = false
    vim.bo[blackboard_state.blackboard_buf].swapfile = false
  end

  vim.api.nvim_win_set_width(blackboard_state.blackboard_win, math.floor(vim.o.columns / 5))
  vim.api.nvim_win_set_buf(blackboard_state.blackboard_win, blackboard_state.blackboard_buf)
  vim.wo[blackboard_state.blackboard_win].number = false
  vim.wo[blackboard_state.blackboard_win].relativenumber = false
  vim.wo[blackboard_state.blackboard_win].wrap = false
end

---@param groupedMarks table<string, table>
---@return table
local function parseGroupedMarksInfo(groupedMarks)
  local blackboardLines = {}
  local fileVirtualLines = {} -- filename virtual lines (one per group)
  local funcVirtualLines = {} -- function virtual lines (one per function block)

  -- Process each file group.
  for filename, marks in pairs(groupedMarks) do
    table.sort(marks, function(a, b)
      return a.mark < b.mark
    end)

    -- Instead of inserting the filename in the buffer, record a virtual line.
    local groupStartLine = #blackboardLines + 1
    fileVirtualLines[groupStartLine] = filename

    -- Track the last function name so that we only add a new virtual line when it changes.
    local lastFunc = nil
    for _, mark in ipairs(marks) do
      if mark.nearest_func and mark.nearest_func ~= lastFunc then
        -- Record a virtual line for the function name.
        local currentLine = #blackboardLines + 1
        -- Prepend a marker (like "├─ ") to show it as a header.
        funcVirtualLines[currentLine] = '├─ ' .. mark.nearest_func
        lastFunc = mark.nearest_func
      end
      -- Add the mark’s actual text to the buffer.
      local lineText = string.format(' ├─ %s: %s', mark.mark, mark.text)
      table.insert(blackboardLines, lineText)
    end
  end

  return {
    blackboardLines = blackboardLines,
    fileVirtualLines = fileVirtualLines,
    funcVirtualLines = funcVirtualLines,
  }
end

---@param parsedMarks table
local function addHighlights(parsedMarks)
  local blackboardLines = parsedMarks.blackboardLines

  vim.api.nvim_set_hl(0, 'MarkHighlight', { fg = '#f1c232' })
  for lineIdx, line in ipairs(blackboardLines) do
    local markMatch = line:match '├─%s([A-Za-z]):'
    if markMatch then
      local endCol = line:find(markMatch .. ':')
      if endCol then
        vim.api.nvim_buf_add_highlight(blackboard_state.blackboard_buf, -1, 'MarkHighlight', lineIdx - 1, endCol - 1, endCol)
      end
    end
  end
end

---@param parsedMarks table
local function addVirtualLines(parsedMarks)
  local ns = vim.api.nvim_create_namespace 'blackboard_extmarks'

  -- Add the filename virtual lines.
  vim.api.nvim_set_hl(0, 'FileHighlight', { fg = '#5097A4' })
  for lineNum, filename in pairs(parsedMarks.fileVirtualLines) do
    local extmarkLine = lineNum - 1
    local virtLinesAbove = extmarkLine > 0 -- for line 0, virt_lines_above may not render
    vim.api.nvim_buf_set_extmark(blackboard_state.blackboard_buf, ns, extmarkLine, 0, {
      virt_lines = { { { filename, 'FileHighlight' } } },
      virt_lines_above = virtLinesAbove,
      hl_mode = 'combine',
    })
  end

  -- Add the function name virtual lines.
  vim.api.nvim_set_hl(0, 'FuncHighlight', { fg = '#c678dd' }) -- adjust color as desired
  for lineNum, funcLine in pairs(parsedMarks.funcVirtualLines) do
    local extmarkLine = lineNum - 1
    local virtLinesAbove = extmarkLine > 0
    vim.api.nvim_buf_set_extmark(blackboard_state.blackboard_buf, ns, extmarkLine, 0, {
      virt_lines = { { { funcLine, 'FuncHighlight' } } },
      virt_lines_above = virtLinesAbove,
      hl_mode = 'combine',
    })
  end
end

local function toggle_mark_window()
  blackboard_state.original_win = vim.api.nvim_get_current_win()
  blackboard_state.original_buf = vim.api.nvim_get_current_buf()

  if vim.api.nvim_win_is_valid(blackboard_state.blackboard_win) then
    vim.api.nvim_win_hide(blackboard_state.blackboard_win)
    vim.api.nvim_del_augroup_by_name 'blackboard_group'
    return
  end

  create_new_blackboard()
  Create_autocmd(blackboard_state)

  local groupedMarks = Group_marks_info_by_file()
  local parsedMarks = parseGroupedMarksInfo(groupedMarks)
  local lines = parsedMarks.blackboardLines

  vim.api.nvim_buf_set_lines(blackboard_state.blackboard_buf, 0, -1, false, lines)

  addHighlights(parsedMarks)
  addVirtualLines(parsedMarks)

  vim.bo[blackboard_state.blackboard_buf].readonly = true
  vim.api.nvim_set_current_win(blackboard_state.original_win)
end
vim.keymap.set('n', '<leader>tm', toggle_mark_window, { desc = '[T]oggle [M]arklist' })

return {
  toggle_mark_window = toggle_mark_window,
  jump_to_mark = jump_to_mark,
}
