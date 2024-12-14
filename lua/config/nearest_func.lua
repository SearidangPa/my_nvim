local ts_utils = require 'nvim-treesitter.ts_utils'
local get_node_text = vim.treesitter.get_node_text

function GetEnclosingFunctionName()
  local node = ts_utils.get_node_at_cursor()

  while node do
    if node:type() ~= 'function_declaration' then
      node = node:parent() -- Traverse up the node tree to find a function node
      goto continue
    end

    local func_name_node = node:child(1)
    if func_name_node then
      local func_name = get_node_text(func_name_node, 0)
      local startLine, _, _ = node:start()
      return startLine + 1, func_name -- +1 to convert 0-based to 1-based lua indexing system
    end

    ::continue::
  end

  return nil
end

vim.keymap.set('n', '<leader>fn', function()
  local startLine, func_name = GetEnclosingFunctionName()
  print(string.format('Enclosing function name: %s at line %d', func_name, startLine))
end, { desc = 'Print the enclosing function name' })
