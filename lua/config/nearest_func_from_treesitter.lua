local ts_locals = require 'nvim-treesitter.locals'
local ts_utils = require 'nvim-treesitter.ts_utils'

-- Adapted from https://github.com/tjdevries/config_manager/blob/1a93f03dfe254b5332b176ae8ec926e69a5d9805/xdg_config/nvim/lua/tj/snips/ft/go.lua
vim.treesitter.query.set(
  'go',
  'LuaSnip_Result',
  [[ [
    (method_declaration result: (_) @id)
    (function_declaration result: (_) @id)
    (func_literal result: (_) @id)
  ] ]]
)

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

  local query = vim.treesitter.query.get('go', 'LuaSnip_Result')

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

vim.keymap.set('n', '<leader>f', print_nearest_func, { desc = 'Print the nearest function' })
