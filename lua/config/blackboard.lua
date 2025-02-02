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

---@param groupedMarks table<string, table>
---@return table
local function parseGroupedMarksInfo(groupedMarks)
  local blackboardLines = {}
  local virtualLines = {}

  for filename, marks in pairs(groupedMarks) do
    table.sort(marks, function(a, b)
      return a.mark < b.mark
    end)

    if #blackboardLines == 0 then
      table.insert(blackboardLines, filename)
    end

    local groupStartLine = #blackboardLines + 1

    for _, mark in ipairs(marks) do
      local currentLine = #blackboardLines + 1
      virtualLines[currentLine] = {
        filename = filename,
        func_name = mark.nearest_func,
      }
      if mark.nearest_func then
        table.insert(blackboardLines, string.format('╰─%s: %s', mark.mark, mark.text))
      else
        table.insert(blackboardLines, string.format('🔥%s: %s', mark.mark, mark.text))
      end
    end
  end

  return {
    blackboardLines = blackboardLines,
    virtualLines = virtualLines,
  }
end

---@param parsedMarks table
local function addHighlights(parsedMarks)
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
  vim.api.nvim_buf_add_highlight(blackboard_state.blackboard_buf, -1, 'FileHighlight', 0, 0, -1)
end

---@param data table
local function make_func_line(data)
  if not data.func_name then
    return ''
  end
  return '❯ ' .. data.func_name
end

---@param parsedMarks table
local function addVirtualLines(parsedMarks)
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
      local virt_lines
      if funcLine == '' then
        if filename == last_seen_filename then
          virt_lines = nil
        else
          virt_lines = { { { '', '' } }, { { filename, 'FileHighlight' } } }
        end
      else
        if filename == last_seen_filename then
          if funcLine == last_seen_func then
            virt_lines = nil
          else
            virt_lines = { { { funcLine, '@function' } } }
          end
        else
          if funcLine == last_seen_func then
            virt_lines = { { { '', '' } }, { { filename, 'FileHighlight' } } }
          else
            virt_lines = { { { '', '' } }, { { filename, 'FileHighlight' } }, { { funcLine, '@function' } } }
          end
        end
      end

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

local function toggle_mark_window()
  blackboard_state.original_win = vim.api.nvim_get_current_win()
  blackboard_state.original_buf = vim.api.nvim_get_current_buf()

  if vim.api.nvim_win_is_valid(blackboard_state.blackboard_win) then
    vim.api.nvim_win_hide(blackboard_state.blackboard_win)
    vim.api.nvim_buf_delete(blackboard_state.blackboard_buf, { force = true })
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
