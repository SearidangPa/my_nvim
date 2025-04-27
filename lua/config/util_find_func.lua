local M = {}

local get_node_text = vim.treesitter.get_node_text
local ts_utils = require 'nvim-treesitter.ts_utils'

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

function Nearest_func_name()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line = cursor_pos[1] - 1
  local func_node = M.nearest_function_at_line(bufnr, line)
  assert(func_node, 'No function found')
  for child in func_node:iter_children() do
    if child:type() == 'identifier' or child:type() == 'field_identifier' or child:type() == 'name' then
      return vim.treesitter.get_node_text(child, bufnr)
    end
  end
end

vim.api.nvim_create_user_command('NearestFuncName', function()
  local func_name = Nearest_func_name()
  print('Nearest func name: ' .. func_name)
end, {})

---@return TSNode
function Nearest_func_node()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line = cursor_pos[1] - 1
  local func_node = M.nearest_function_at_line(bufnr, line)
  assert(func_node, 'No function found')
  return func_node
end

function Get_enclosing_fn_info()
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

M.visual_function = function()
  local func_node = Nearest_func_node()
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
map('n', '<leader>vf', M.visual_function, { desc = 'Visual nearest function' })
map('n', '<leader>df', M.delete_function, { desc = 'Delete nearest function' })

return M
