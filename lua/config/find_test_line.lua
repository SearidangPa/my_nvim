Find_test_line_brute = function(bufnr, test_name)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false) -- Get all lines from the buffer
  for i, line in ipairs(lines) do
    -- Match test functions, such as `func TestSomething(t *testing.T)`
    if line:match('^%s*func%s+' .. test_name .. '%s*%(') then
      return i - 1 -- Return 0-indexed line
    end
  end
  return nil
end

local test_function_query_string = [[
(function_declaration
  name: (identifier) @name
  parameters: (parameter_list
    (parameter_declaration
      name: (identifier)
      type: (pointer_type
        (qualified_type
          package: (package_identifier) @package_name
          name: (type_identifier) @type_name))))
  (#eq? @package_name "testing")
  (#eq? @type_name "T")
  (#eq? @name "%s")
]]

Find_test_line = function(go_bufnr, name)
  local formatted = string.format(test_function_query_string, name)
  local query = vim.treesitter.query.parse('go', formatted)
  local parser = vim.treesitter.get_parser(go_bufnr, 'go', {})
  local tree = parser:parse()[1]
  local root = tree:root()

  for id, node in query:iter_captures(root, go_bufnr, 0, -1) do
    if id == 1 then
      local start_line, _, _, _ = node:range()
      return start_line + 1
    end
  end
end

vim.keymap.set('n', '<leader>ftl', function()
  local name = vim.fn.input 'Test name: '
  local line = Find_test_line(vim.api.nvim_get_current_buf(), name)
  print('Test line:', line)
end, { desc = '[F]ind [T]est [L]ine' })
