local get_node_text = vim.treesitter.get_node_text

local test_function_query_string = [[
(function_declaration
  name: (identifier) @name
  parameters: (parameter_list
    (parameter_declaration
      name: (identifier)
      type: (pointer_type
        (qualified_type
          package: (package_identifier) 
          name: (type_identifier) ))))
  (#eq? @name "%s")
)  
]]

local find_test_line_by_name = function(go_bufnr, testName)
  local formatted = string.format(test_function_query_string, testName)
  local query = vim.treesitter.query.parse('go', formatted)
  local parser = vim.treesitter.get_parser(go_bufnr, 'go', {})
  local tree = parser:parse()[1]
  local root = tree:root()

  for _, node in query:iter_captures(root, go_bufnr, 0, -1) do
    local nodeContent = get_node_text(node, go_bufnr)

    if nodeContent == testName then
      local start_line, _, _, _ = node:range()
      return start_line + 1
    end
  end
end

vim.keymap.set('n', '<leader>ft', function()
  local _, testName = GetEnclosingFunctionName()
  local line = find_test_line_by_name(vim.api.nvim_get_current_buf(), testName)
  print(string.format('test name: %s, line: %d', testName, line))
end, { desc = '[F]ind [T]est' })

--[[
 === All tests in the current buffer 
--]]

local function_query = [[
(function_declaration
  name: (identifier) @name
  parameters: (parameter_list
    (parameter_declaration
      name: (identifier)
      type: (pointer_type
        (qualified_type
          package: (package_identifier) @_package_name
          name: (type_identifier) ))))
)  
]]

Find_all_tests = function(go_bufnr)
  local query = vim.treesitter.query.parse('go', function_query)
  local parser = vim.treesitter.get_parser(go_bufnr, 'go', {})
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(root, 'root is nil')

  local res = {}
  for _, node in query:iter_captures(root, go_bufnr, 0, -1) do
    if node == nil then
      return res
    end
    local nodeContent = get_node_text(node, go_bufnr)

    -- all tests start with Test_
    if not string.match(nodeContent, 'Test_') then
      goto continue
    end

    res[nodeContent] = node:start() + 1
    ::continue::
  end
  return res
end

vim.keymap.set('n', '<leader>fat', function()
  local testsCurrBuf = Find_all_tests(vim.api.nvim_get_current_buf())
  for testName, line in pairs(testsCurrBuf) do
    print(string.format('test name: %s, line: %d', testName, line))
  end
  vim.notify(vim.fn.execute 'messages')
end, { desc = '[F]ind [A]ll [T]ests' })
