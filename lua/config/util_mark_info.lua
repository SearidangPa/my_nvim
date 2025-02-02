local plenary_filetype = require 'plenary.filetype'

local function add_mark_info(marks_info, mark, bufnr, line, col)
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- for tree-sitter
  local filetype = plenary_filetype.detect_from_extension(filepath)
  vim.bo[bufnr].filetype = filetype

  local nearest_func = Nearest_function_at_line(bufnr, line)
  local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''

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
    text = vim.trim(text),
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

function Retrieve_mark_info(mark_char)
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

function Group_marks_info_by_file()
  local all_accessible_marks = Get_accessible_marks_info()
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

--- @return table
function Get_accessible_marks_info()
  local marks_info = {}
  local cwd = vim.fn.getcwd()
  for char = string.byte 'A', string.byte 'Z' do
    add_global_mark_info(marks_info, char, cwd)
  end
  add_local_marks(marks_info)

  return marks_info
end

--- @param blackboard_state table
--- @return string
function Get_mark_char(blackboard_state)
  if not vim.api.nvim_buf_is_valid(blackboard_state.blackboard_buf) then
    vim.notify('blackboard buffer is invalid', vim.log.levels.ERROR)
    return ''
  end
  local line_num = vim.fn.line '.'
  local line_text = vim.fn.getline(line_num)

  local mark_char = line_text:match '([A-Z]):' or line_text:match '([a-z]):'
  return mark_char
end
