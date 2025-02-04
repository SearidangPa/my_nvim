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

function Find_all_tests (go_bufnr)
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



function Nearest_function_at_line(bufnr, line)
  local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype) -- Get language from filetype
  local parser = vim.treesitter.get_parser(bufnr, lang)
  assert(parser, 'parser is nil')
  local tree = parser:parse()[1]
  assert(tree, 'tree is nil')
  local root = tree:root()
  assert(root, 'root is nil')

  local function traverse(node)
    local nearest_function = nil
    for child in node:iter_children() do
      if child:type() == 'function_declaration' or child:type() == 'method_declaration' then
        local start_row, _, end_row, _ = child:range()
        if start_row <= line and end_row >= line then
          for subchild in child:iter_children() do
            if subchild:type() == 'identifier' or subchild:type() == 'name' then
              nearest_function = vim.treesitter.get_node_text(subchild, bufnr)
              break
            end
          end
        end
      end
      if not nearest_function then
        nearest_function = traverse(child)
      end
      if nearest_function then
        break
      end
    end
    return nearest_function
  end

  return traverse(root)
end

function Nearest_function_decl_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local parser = vim.treesitter.get_parser(bufnr, lang)
  if not parser then
    return "" end

  local tree = parser:parse()[1]
  if not tree then
    return ""
  end

  local cursor_node = ts_utils.get_node_at_cursor()
  if not cursor_node then
    return ""
  end

  local function_node = cursor_node

  while function_node do
    if function_node:type() == 'function_declaration' or function_node:type() == 'method_declaration' then
      for child in function_node:iter_children() do
        if child:type() == 'identifier' then
          local function_name = get_node_text(child, bufnr)
          return function_name
        end
      end
    end
    function_node = function_node:parent()
  end
end

vim.api.nvim_create_user_command('NearestFunc', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line = cursor_pos[1] - 1
  local func_name = Nearest_function_at_line(bufnr, line)
  if func_name then
    print("Nearest function:", func_name)
  else
    print("No function found")
  end
end, {})
