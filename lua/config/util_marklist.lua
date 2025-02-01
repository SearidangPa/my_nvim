local plenary_filetype = require 'plenary.filetype'

local function add_mark_info(marks_info, mark, bufnr, line, col)
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- for tree-sitter
  local filetype = plenary_filetype.detect_from_extension(filepath)
  vim.bo[bufnr].filetype = filetype

  local nearest_func = Nearest_function_at_line(bufnr, line)
  local text
  if not nearest_func then
    text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
  end

  local filename = vim.fn.fnamemodify(filepath, ':t')
  table.insert(marks_info, {
    mark = mark,
    filename = filename,
    line = line,
    col = col,
    filetype = filetype,
    nearest_func = nearest_func,
    text = text,
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

function Get_accessible_marks_info()
  local marks_info = {}
  local cwd = vim.fn.getcwd()
  for char = string.byte 'A', string.byte 'Z' do
    add_global_mark_info(marks_info, char, cwd)
  end
  add_local_marks(marks_info)

  return marks_info
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
