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



local function get_nearest_function(bufnr, line)
  local ts = vim.treesitter
  local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype) -- Get language from filetype
  local parser = vim.treesitter.get_parser(bufnr, lang)
  if not parser then return nil end

  local tree = parser:parse()[1]
  if not tree then return nil end

  local root = tree:root()
  if not root then return nil end

  local function traverse(node)
    local nearest_function = nil
    for child in node:iter_children() do
      -- Check if the child is a function declaration
      if child:type() == "function_declaration" or child:type() == "method_declaration" then
        local start_row, _, end_row, _ = child:range()
        -- Check if the line is within this function's range
        if start_row <= line and end_row >= line then
          -- Find the first `identifier` child, which is usually the function name
          for subchild in child:iter_children() do
            if subchild:type() == "identifier" or subchild:type() == "name" then
              nearest_function = vim.treesitter.get_node_text(subchild, bufnr)
              break
            end
          end
        end
      end

      -- Recursively search deeper
      if not nearest_function then
        nearest_function = traverse(child)
      end
      if nearest_function then break end
    end
    return nearest_function
  end

  return traverse(root)
end



vim.api.nvim_create_user_command('NearestFunc', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line = cursor_pos[1] - 1
  local func_name = get_nearest_function(bufnr, line)
  if func_name then
    print("Nearest function:", func_name)
  else
    print("No function found")
  end
end, {})


function Nearest_function_decl_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local parser = vim.treesitter.get_parser(bufnr, lang)
  if not parser then
    print 'Treesitter parser not found for Go'
    return "" end

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
          local function_name = get_node_text(child, bufnr)
          print('nearest function:', function_name)
          return function_name
        end
      end
    end
    function_node = function_node:parent()
  end

  print 'No function declaration found'
end

vim.api.nvim_create_user_command('NearestFuncDecl',Nearest_function_decl_at_cursor, {})

local function move_to_next_valid_field_identifier()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]

  local ts = vim.treesitter
  local parser = ts.get_parser(bufnr, "go")
  local tree = parser:parse()[1]
  local root = tree:root()

  local function is_valid_field_identifier(node)
    local parent = node:parent()
    return parent and parent:type() == "selector_expression" and parent:parent() and parent:parent():type() == "call_expression"
  end

  local function find_next(node, row, col)
    for child in node:iter_children() do
      if child:type() == "field_identifier" and is_valid_field_identifier(child) then
        local start_row, start_col = child:range()
        if start_row > row or (start_row == row and start_col > col) then
          return child
        end
      end

      local descendant = find_next(child, row, col)
      if descendant then
        return descendant
      end
    end
    return nil
  end

  local next_node = find_next(root, current_row, current_col)

  if next_node then
    local start_row, start_col = next_node:range()
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  else
    print("No further valid field_identifier found")
  end
end

vim.keymap.set("n", "]f", move_to_next_valid_field_identifier, { desc = "Move to next valid field_identifier" })

local function move_to_previous_valid_field_identifier()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]

  local ts = vim.treesitter
  local parser = ts.get_parser(bufnr, "go")
  local tree = parser:parse()[1]
  local root = tree:root()

  local function is_valid_field_identifier(node)
    local parent = node:parent()
    return parent and parent:type() == "selector_expression" and parent:parent() and parent:parent():type() == "call_expression"
  end

  local function find_previous(node, row, col)
    local previous_node = nil

    local function search(node, row, col)
      for child in node:iter_children() do
        if child:type() == "field_identifier" and is_valid_field_identifier(child) then
          local start_row, start_col = child:range()
          if start_row < row or (start_row == row and start_col < col) then
            previous_node = child
          end
        end
        search(child, row, col)
      end
    end

    search(node, row, col)
    return previous_node
  end

  local previous_node = find_previous(root, current_row, current_col)

  if previous_node then
    local start_row, start_col = previous_node:range()
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  else
    print("No previous valid field_identifier found")
  end
end

vim.keymap.set("n", "[f", move_to_previous_valid_field_identifier, { desc = "Move to previous valid field_identifier" })
