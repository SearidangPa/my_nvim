local ts_utils = require 'nvim-treesitter.ts_utils'
local get_node_text = vim.treesitter.get_node_text

function GetEnclosingFunctionName()
  local node = ts_utils.get_node_at_cursor()

  while node do
    if node:type() == 'function_declaration' then
      local func_name_node = node:child(1)
      if func_name_node then
        local func_name = get_node_text(func_name_node, 0)
        print('Enclosing function name: ' .. func_name)
        return func_name
      end
    end
    node = node:parent() -- Traverse up the node tree to find a function node
  end

  print 'No enclosing function found.'
  return nil
end

vim.keymap.set('n', '<leader>nf', function()
  Go_result_type {
    index = 0,
    func_name = 'nothing',
  }
end, { desc = 'Trying to print the nearest function' })

vim.keymap.set('n', '<leader>fn', function()
  GetEnclosingFunctionName()
end, { desc = 'Print the enclosing function name' })
