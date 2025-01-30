local plenary_filetype = require 'plenary.filetype'
local a = require 'plenary.async'

function Get_global_marks()
  local marks = {}
  local cwd = vim.fn.getcwd()
  for char = string.byte 'A', string.byte 'Z' do
    local mark = string.char(char)
    local pos = vim.fn.getpos("'" .. mark)
    if pos[1] ~= 0 then
      local bufnr = pos[1]
      local line = pos[2]
      local col = pos[3]
      local filepath = vim.fn.bufname(bufnr)
      local abs_filepath = vim.fn.fnamemodify(filepath, ':p')
      if abs_filepath:find(cwd, 1, true) then
        local filename = vim.fn.fnamemodify(filepath, ':t')
        local filetype = plenary_filetype.detect_from_extension(filepath)
        vim.bo[bufnr].filetype = filetype
        local nearest_func_at_line = Nearest_function_at_line(bufnr, line)
        table.insert(marks, {
          mark = mark,
          bufnr = bufnr,
          filename = filename ~= '' and filename or '[No Name]',
          filepath = abs_filepath,
          line = line,
          col = col,
          nearest_func = nearest_func_at_line,
          text = vim.fn.getbufline(bufnr, line)[1],
        })
      end
    end
  end
  return marks
end

function Get_local_marks()
  local marks = {}
  local mark_list = vim.fn.getmarklist(0)

  for _, mark_entry in ipairs(mark_list) do
    local mark = mark_entry.mark:sub(2, 2)
    if mark:match '[a-z]' then
      local bufnr = mark_entry.pos[1]
      local line = mark_entry.pos[2]
      local col = mark_entry.pos[3]

      if vim.api.nvim_buf_is_valid(bufnr) then
        local filepath = vim.fn.bufname(bufnr)
        local abs_filepath = vim.fn.fnamemodify(filepath, ':p')

        local filename = vim.fn.fnamemodify(filepath, ':t')
        local nearest_func_at_line = Nearest_function_at_line(bufnr, line)
        local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''

        table.insert(marks, {
          mark = mark,
          bufnr = bufnr,
          filename = filename ~= '' and filename or '[No Name]',
          filepath = abs_filepath,
          line = line,
          col = col,
          nearest_func = nearest_func_at_line,
          text = text,
        })
      end
    end
  end
  return marks
end

function Get_all_marks()
  local global_marks = Get_global_marks()
  local local_marks = Get_local_marks()
  local all_marks = vim.list_extend(global_marks, local_marks)
  return all_marks
end
