local plenary_filetype = require 'plenary.filetype'

--- @param mark_list table
local function get_marks_info_from_list(mark_list)
  local marks_info = {}
  local cwd = vim.fn.getcwd()
  for _, mark_entry in ipairs(mark_list) do
    local mark = mark_entry.mark:sub(2, 2)
    if mark:match '[A-Z]' then
      local bufnr = mark_entry.pos[1]
      local line = mark_entry.pos[2]
      local col = mark_entry.pos[3]

      local filepath = vim.fn.bufname(bufnr)
      local abs_filepath = vim.fn.fnamemodify(filepath, ':p')
      if abs_filepath:find(cwd, 1, true) then
        local filename = vim.fn.fnamemodify(filepath, ':t')

        -- for tree-sitter
        local filetype = plenary_filetype.detect_from_extension(filepath)
        vim.bo[bufnr].filetype = filetype

        local nearest_func = Nearest_function_at_line(bufnr, line)
        local text
        if nearest_func then
          text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
        end

        table.insert(marks_info, {
          mark = mark,
          bufnr = bufnr,
          filename = filename ~= '' and filename or '[No Name]',
          filepath = abs_filepath,
          line = line,
          col = col,
          nearest_func = nearest_func,
          text = text,
        })
      end
    end
  end
  return marks_info
end

function Get_marks_info()
  local local_mark_list = vim.fn.getmarklist(0)
  local local_marks = get_marks_info_from_list(local_mark_list)

  local global_mark_list = vim.fn.getmarklist()
  local global_marks = get_marks_info_from_list(global_mark_list)
  return vim.list_extend(global_marks, local_marks)
end

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
