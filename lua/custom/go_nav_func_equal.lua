local M = {}

local ignore_list = {
  Join = true,
}

local function get_root_node()
  local buf_nr = vim.api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local parser = vim.treesitter.get_parser(buf_nr, lang)
  assert(parser, 'Parser is nil')
  local tree = parser:parse()[1]
  local root = tree:root()
  return root
end

local function call_expr_equal(node)
  local parent = node:parent()
  if not parent or parent:type() ~= 'call_expression' then
    return false
  end

  local call_expr_parent = parent:parent()
  if not call_expr_parent or call_expr_parent:type() ~= 'expression_list' then
    return false
  end

  local expr_list_parent = call_expr_parent:parent()
  if not expr_list_parent then
    return false
  end
  if expr_list_parent:type() == 'short_var_declaration' or expr_list_parent:type() == 'assignment_statement' then
    return true
  end
  return false
end

local function select_call_expr_equal(node)
  local parent = node:parent()
  if not parent then
    return false
  end
  if parent:type() ~= 'selector_expression' then
    return false
  end
  return call_expr_equal(parent)
end

local function find_prev_func_call_with_equal(node, row, col)
  local previous_node = nil

  local function search(n)
    for child in n:iter_children() do
      search(child)

      local candidate = false

      if child:type() == 'field_identifier' and select_call_expr_equal(child) then
        if not ignore_list[vim.treesitter.get_node_text(child, 0)] then
          candidate = true
        end
      elseif child:type() == 'identifier' and call_expr_equal(child) then
        candidate = true
      end

      if candidate then
        local s_row, s_col, _, _ = child:range()
        if s_row < row or (s_row == row and s_col < col) then
          if not previous_node then
            previous_node = child
          else
            local prev_row, prev_col, _, _ = previous_node:range()
            if s_row > prev_row or (s_row == prev_row and s_col > prev_col) then
              previous_node = child
            end
          end
        end
      end
    end
  end

  search(node)
  return previous_node
end

local function find_next_func_call_with_equal(node, row, col)
  for child in node:iter_children() do
    local candidate = nil
    if child:type() == 'field_identifier' and select_call_expr_equal(child) then
      if not ignore_list[vim.treesitter.get_node_text(child, 0)] then
        candidate = child
      end
    elseif child:type() == 'identifier' and call_expr_equal(child) then
      candidate = child
    end

    if candidate then
      local s_row, s_col, _, _ = candidate:range()
      if s_row > row or (s_row == row and s_col > col) then
        return candidate
      end
    end

    local descendant = find_next_func_call_with_equal(child, row, col)
    if descendant then
      return descendant
    end
  end

  return nil
end

local function move_to_next_func_call()
  local count = vim.v.count
  if count == 0 then
    count = 1
  end
  local root = get_root_node()
  for _ = 1, count do
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
    local next_node = find_next_func_call_with_equal(root, current_row, current_col)

    if next_node then
      local start_row, start_col, _, _ = next_node:range()
      vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    end
  end
end

local function move_to_previous_func_call()
  local count = vim.v.count
  if count == 0 then
    count = 1
  end
  local root = get_root_node()
  for _ = 1, count do
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
    local previous_node = find_prev_func_call_with_equal(root, current_row, current_col)

    if previous_node then
      local start_row, start_col, _, _ = previous_node:range()
      vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    end
  end
end

--[[
  - Retrieves the previous function call with an assignment operator.
]]
function M.get_prev_func_call_with_equal()
  local root = get_root_node()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
  local previous_node = find_prev_func_call_with_equal(root, current_row, current_col)
  if previous_node then
    local res = vim.treesitter.get_node_text(previous_node, 0)
    return res
  end
end

vim.keymap.set('n', ']f', move_to_next_func_call, { desc = 'Next function call' })
vim.keymap.set('n', '[f', move_to_previous_func_call, { desc = 'Previous function call' })

return M
