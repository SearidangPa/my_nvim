local function create_floating_window(content)
  local buf = vim.api.nvim_create_buf(false, true)
  local testsCurrBuf = Find_all_tests(vim.api.nvim_get_current_buf())
  local testNames = ''
  for testName, line in pairs(testsCurrBuf) do
    testNames = testNames .. string.format('test name: %s, line: %d', testName, line)
  end

  table.insert(content, testNames)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

  local width = vim.api.nvim_get_option 'columns'
  local height = vim.api.nvim_get_option 'lines'
  print(width, height)

  local win_height = 30
  local win_width = 80
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

vim.api.nvim_create_user_command('CreateFloatingWindow', function()
  create_floating_window { 'Custom Floating Window', 'More Text Here', 'It works!' }
end, {})
