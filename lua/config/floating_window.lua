function Create_floating_window(content, start_line, end_line)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, start_line, end_line, false, content)

  local width = vim.opt.columns:get()
  local height = vim.opt.lines:get()
  print(width, height)

  local win_height = 60
  local win_width = 130
  local row = math.floor((height - win_height) / 2)
  local col = math.floor((width - win_width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  return win, buf
end
