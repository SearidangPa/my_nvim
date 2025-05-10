local M = {}

---@param bufnr number
---@param line number
---@return TSNode|nil
M.nearest_function_at_line = function(bufnr, line)
  local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype) -- Get language from filetype
  local parser = vim.treesitter.get_parser(bufnr, lang)
  assert(parser, 'parser is nil')
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(tree, 'tree is nil')
  assert(parser, 'parser is nil')
  assert(root, 'root is nil')

  local function traverse(node)
    local nearest_function = nil
    for child in node:iter_children() do
      if child:type() == 'function_declaration' or child:type() == 'method_declaration' then
        local start_row, _, end_row, _ = child:range()
        if start_row <= line and end_row >= line then
          nearest_function = child
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

---@return TSNode
function M.nearest_func_node()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line = cursor_pos[1] - 1
  local func_node = M.nearest_function_at_line(bufnr, line)
  assert(func_node, 'No function found')
  return func_node
end

M.visual_function = function()
  local util_find_func = require 'config.util_find_func'
  local func_node = util_find_func.nearest_func_node()
  local start_row, start_col, end_row, end_col = func_node:range()
  vim.cmd 'normal! v'
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  vim.cmd 'normal! o'
  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
end

M.delete_function = function()
  M.visual_function()
  vim.cmd 'normal! d'
end

local map = vim.keymap.set
map('n', '<leader>vf', M.visual_function, { desc = '[V]isual nearest [f]unction' })
map('n', '<localleader>df', M.delete_function, { desc = '[D]elete nearest function' })

return M
