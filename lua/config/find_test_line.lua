Find_test_line = function(bufnr, test_name)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false) -- Get all lines from the buffer
  for i, line in ipairs(lines) do
    -- Match test functions, such as `func TestSomething(t *testing.T)`
    if line:match('^%s*func%s+' .. test_name .. '%s*%(') then
      return i - 1 -- Return 0-indexed line
    end
  end
  return nil
end
