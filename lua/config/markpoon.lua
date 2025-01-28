local function get_global_marks()
  local marks = {}
  for char = string.byte 'A', string.byte 'Z' do
    local mark = string.char(char)
    local pos = vim.fn.getpos("'" .. mark)
    if pos[1] ~= 0 then -- Check if the mark is valid
      local bufnr = pos[1]
      local line = pos[2]
      local col = pos[3]
      local filepath = vim.fn.bufname(bufnr)
      local filename = vim.fn.fnamemodify(filepath, ':t') -- Get only the file name
      table.insert(marks, {
        mark = mark,
        bufnr = bufnr,
        filename = filename ~= '' and filename or '[No Name]',
        line = line,
        col = col,
        text = vim.fn.getbufline(bufnr, line)[1],
      })
    end
  end
  return marks
end

local function handle_mark_choice(choice)
  if not choice then
    vim.notify('No mark selected', vim.log.levels.INFO)
    return
  end
  local line, col, bufnr = choice.line, choice.col, choice.bufnr
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_win_set_cursor(0, { line, col })
  vim.cmd 'normal! zz'
end

local function select_mark()
  local marks = get_global_marks()
  if #marks == 0 then
    vim.notify('No global marks found', vim.log.levels.INFO)
    return
  end

  local opts = {
    prompt = 'Select mark:',
    format_item = function(item)
      return string.format("'%s': %s -> %s", item.mark, item.filename, item.text)
    end,
  }

  vim.ui.select(marks, opts, function(choice)
    handle_mark_choice(choice)
  end)
end

vim.keymap.set('n', '<leader>gm', select_mark, { desc = '[G]lobal [M]ark' })
