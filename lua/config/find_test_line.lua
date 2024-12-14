local get_node_text = vim.treesitter.get_node_text

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
)  
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

  for _, node in query:iter_captures(root, go_bufnr, 0, -1) do
    local nodeContent = get_node_text(node, go_bufnr)
    if nodeContent == name then
      local start_line, _, _, _ = node:range()
      return start_line + 1
    end
  end
end

vim.keymap.set('n', '<leader>ftl', function()
  local _, testName = GetEnclosingFunctionName()
  local line = Find_test_line(vim.api.nvim_get_current_buf(), testName)
  print(string.format('test name: %s, line: %d', testName, line))
end, { desc = '[F]ind [T]est [L]ine' })
