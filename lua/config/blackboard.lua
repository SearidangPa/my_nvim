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

local function load_buf_preemptively(from)
  if vim.api.nvim_buf_is_loaded(from) then
    return
  end
  vim.cmd(('noa call bufload(%d)'):format(from))
end

---@param groupedMarks table<string, table>
---@return table
local function parse_grouped_marks_info(groupedMarks)
  local blackboardLines = {}
  local funcHighlightPositions = {}
  local fileVirtualLines = {}

  for filename, marks in pairs(groupedMarks) do
    table.sort(marks, function(a, b)
      return a.mark < b.mark
    end)

    if #blackboardLines == 0 then
      table.insert(blackboardLines, filename)
    end

    local groupStartLine = #blackboardLines + 1

    for i, mark in ipairs(marks) do
      local lineText = string.format(' ├─ %s: %s', mark.mark, mark.text)
      table.insert(blackboardLines, lineText)

      load_buf_preemptively(mark.bufnr)

      if mark.nearest_func then
        local lineIndex = #blackboardLines
        local colStart = #string.format(' ├─ %s: ', mark.mark)
        local colEnd = colStart + #mark.nearest_func
        table.insert(funcHighlightPositions, { lineIndex, colStart, colEnd })
      end
    end

    fileVirtualLines[groupStartLine] = filename
  end

  return {
    blackboardLines = blackboardLines,
    funcHighlightPositions = funcHighlightPositions,
    fileVirtualLines = fileVirtualLines,
  }
end

---@param parsedMarks table
local function add_highlights(parsedMarks)
  local blackboardLines = parsedMarks.blackboardLines
  local funcHighlightPositions = parsedMarks.funcHighlightPositions

  for _, pos in ipairs(funcHighlightPositions) do
    local lineIdx, colStart, colEnd = unpack(pos)
    vim.api.nvim_buf_add_highlight(blackboard_state.blackboard_buf, 0, '@function', lineIdx - 1, colStart, colEnd)
  end

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
local function add_file_virtual_lines(parsedMarks)
  vim.api.nvim_set_hl(0, 'FileHighlight', { fg = '#5097A4' })
  local ns = vim.api.nvim_create_namespace 'blackboard_extmarks'
  vim.api.nvim_buf_add_highlight(blackboard_state.blackboard_buf, -1, 'FileHighlight', 0, 0, -1)

  for lineNum, filename in pairs(parsedMarks.fileVirtualLines) do
    local extmarkLine = lineNum - 1
    if extmarkLine > 1 then
      vim.api.nvim_buf_set_extmark(blackboard_state.blackboard_buf, ns, extmarkLine, 0, {
        virt_lines = { { { filename, 'FileHighlight' } } },
        virt_lines_above = true,
        hl_mode = 'combine',
      })
    end
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
  local parsedMarks = parse_grouped_marks_info(groupedMarks)

  local lines = parsedMarks.blackboardLines
  vim.api.nvim_buf_set_lines(blackboard_state.blackboard_buf, 0, -1, false, lines)

  add_highlights(parsedMarks)
  add_file_virtual_lines(parsedMarks)

  vim.bo[blackboard_state.blackboard_buf].readonly = true
  vim.api.nvim_set_current_win(blackboard_state.original_win)
end

vim.keymap.set('n', '<leader>tm', toggle_mark_window, { desc = '[T]oggle [M]arklist' })

return {
  toggle_mark_window = toggle_mark_window,
  jump_to_mark = jump_to_mark,
}
