function Set_filetype_by_extension(filename, bufnr)
  -- Get the filename of the buffer
  -- Extract the file extension
  local ext = filename:match '^.+%.(.+)$'
  if not ext then
    print('No file extension found for buffer ' .. filename)
    return
  end

  -- Map file extensions to filetypes
  local filetype_map = {
    go = 'go',
    lua = 'lua',
    py = 'python',
    -- Add more extensions as needed
  }

  -- Set the filetype if it's in the map
  local filetype = filetype_map[ext]
  if filetype then
    vim.bo[bufnr].filetype = filetype
  else
    print('No filetype mapping for extension: ' .. ext)
  end
end

function Get_global_marks()
  local marks = {}
  local cwd = vim.fn.getcwd() -- Get the current working directory
  for char = string.byte 'A', string.byte 'Z' do
    local mark = string.char(char)
    local pos = vim.fn.getpos("'" .. mark)
    if pos[1] ~= 0 then -- Check if the mark is valid
      local bufnr = pos[1]
      local line = pos[2]
      local col = pos[3]
      local filepath = vim.fn.bufname(bufnr)
      local abs_filepath = vim.fn.fnamemodify(filepath, ':p') -- Convert to absolute path
      -- Check if the file is under the current working directory
      if abs_filepath:find(cwd, 1, true) then
        local filename = vim.fn.fnamemodify(filepath, ':t') -- Get only the file name

        Set_filetype_by_extension(filename, bufnr)
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

local function get_local_marks()
  local marks = {}
  local cwd = vim.fn.getcwd() -- Get the current working directory
  local mark_list = vim.fn.getmarklist(0) -- Get marks for the current buffer only

  for _, mark_entry in ipairs(mark_list) do
    local mark = mark_entry.mark:sub(2, 2) -- Extract the mark character (e.g., 'a', 'b', ...)
    if mark:match '[a-z]' then -- Ensure it's a local mark
      local bufnr = mark_entry.pos[1]
      local line = mark_entry.pos[2]
      local col = mark_entry.pos[3]

      if vim.api.nvim_buf_is_valid(bufnr) then
        local filepath = vim.fn.bufname(bufnr)
        local abs_filepath = vim.fn.fnamemodify(filepath, ':p')

        local filename = vim.fn.fnamemodify(filepath, ':t')
        local nearest_func_at_line = Nearest_function_at_line(bufnr, line)
        -- Get the text safely
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
  local local_marks = get_local_marks()
  local all_marks = vim.list_extend(global_marks, local_marks)
  return all_marks
end
