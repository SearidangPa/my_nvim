local get_node_text = vim.treesitter.get_node_text
local ts_utils = require('nvim-treesitter.ts_utils')

local test_function_query_string = [[
(function_declaration
  name: (identifier) @name
  parameters: (parameter_list
    (parameter_declaration
      name: (identifier)
      type: (pointer_type
        (qualified_type
          package: (package_identifier) @_package_name
          name: (type_identifier) ))))
  (#eq? @_package_name "testing")
  (#eq? @name "%s")
)
]]

Find_test_line_by_name = function(go_bufnr, testName)
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

function Nearest_function_decl()
  local parser = vim.treesitter.get_parser(0, 'go')
  if not parser then
    print 'Treesitter parser not found for Go'
    return ""
  end

  local tree = parser:parse()[1]
  if not tree then
    print 'Parse tree not found'
    return ""
  end

  local cursor_node = ts_utils.get_node_at_cursor()
  if not cursor_node then
    print 'Cursor node not found'
    return ""
  end

  local function_node = cursor_node

  while function_node do
    if function_node:type() == 'function_declaration' then
      for child in function_node:iter_children() do
        if child:type() == 'identifier' then
          local function_name = get_node_text(child, 0)
          print(function_name)
          return function_name
        end
      end
    end
    function_node = function_node:parent()
  end

  print 'No function declaration found'
end

vim.api.nvim_create_user_command('NearestFuncDecl',Nearest_function_decl, {})
vim.keymap.set('n', '<leader>nf', Nearest_function_decl, {desc = '[N]earest [F]unction Declaration'})










