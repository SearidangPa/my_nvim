local M = {}

-- create a user command that print out the closest test name using treesitter
vim.treesitter.query.set(
  'go',
  'nearest_func_name',
  [[ [
    (method_declaration result: (_) @id)
    (function_declaration result: (_) @id)
    (func_literal result: (_) @id)
  ] ]]
)

local ts_locals = require 'nvim-treesitter.locals'
local ts_utils = require 'nvim-treesitter.ts_utils'
local get_node_text = vim.treesitter.get_node_text

local function handler(node)
  local text = get_node_text(node, 0)
  return { text }
end

local function print_nearest_func()
  local cursor_node = ts_utils.get_node_at_cursor()
  if not cursor_node then
    return {}
  end

  local scope = ts_locals.get_scope_tree(cursor_node, 0)

  local function_node
  for _, v in ipairs(scope) do
    print(string.format('v: %s', v))
    if v:type() == 'function_declaration' or v:type() == 'method_declaration' or v:type() == 'func_literal' then
      function_node = v
      break
    end
  end
  print(string.format('function_node: %s', function_node))

  local query = vim.treesitter.query.get('go', 'nearest_func_name')

  if not query then
    print 'query is nil'
    return {}
  end

  print 'enter nearest_func'
  for _, node in query:iter_captures(function_node, 0) do
    print('node: ', node)
    print(node)

    -- local handlerFunc = handler[node:type()]
    -- if handlerFunc then
    --   return handlerFunc(node)
    -- end
  end

  print 'exit nearest_func'
  return {}
end

M.setup = function()
  vim.keymap.set('n', '<leader>f', print_nearest_func, { desc = 'Print the nearest function' })
end

return M
