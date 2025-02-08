local expr_list_parent_match = {
  'short_var_declaration',
  'assignment_statement',
}

local function is_top_level_field_identifier(node)
  if node:type() ~= 'field_identifier' then
    return false
  end

  local selector = node:parent()
  if not selector or selector:type() ~= 'selector_expression' then
    return false
  end

  if not selector or selector:type() ~= 'selector_expression' then
    return false
  end

  local call_expr = selector:parent()
  if not call_expr or call_expr:type() ~= 'call_expression' then
    return false
  end

  local expr_list = call_expr:parent()
  if not expr_list or expr_list:type() ~= 'expression_list' then
    return false
  end

  local expr_list_parent = expr_list:parent()
  if expr_list_parent then
    if expr_list_parent:type() == 'short_var_declaration' or expr_list_parent:type() == 'assignment_statement' then
      return true
    end
  end
  return false
end

local function is_valid_field_identifier(node)
  local parent = node:parent()
  if not parent then
    return false
  end
  if parent:type() ~= 'selector_expression' then
    return false
  end

  local gparent = parent:parent()
  if gparent and gparent:type() == 'call_expression' then
    return true
  end
  return false
end

local function is_valid_function_call_identifier(node)
  if node:type() ~= 'identifier' then
    return false
  end

  local parent = node:parent()
  if not parent then
    return false
  end

  if parent:type() ~= 'call_expression' then
    return false
  end

  local first_child = nil
  for child in parent:iter_children() do
    first_child = child
    break
  end

  if first_child == node then
    return true
  end
end

-- Revised DFS search that only considers top-level field identifiers.
local function find_previous(node, row, col)
  local previous_node = nil

  local function search(n)
    for child in n:iter_children() do
      search(child)

      local child_type = child:type()
      local consider = false

      if child_type == 'field_identifier' and is_valid_field_identifier(child) then
        -- Only consider this field if it is top-level.
        print(string.format('================= field_identifier at %d, %d', child:range()))
        if is_top_level_field_identifier(child) then
          consider = true
        end
      elseif child_type == 'identifier' and is_valid_function_call_identifier(child) then
        -- Optionally include identifiers, if that’s part of your logic.
        print(string.format('================= identifier at %d, %d', child:range()))
        consider = true
      end

      if consider then
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

local function get_root_node()
  local buf_nr = vim.api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local parser = vim.treesitter.get_parser(buf_nr, lang)
  local tree = parser:parse()[1]
  local root = tree:root()
  return root
end

local function find_next(node, row, col)
  for child in node:iter_children() do
    local candidate = nil
    local child_type = child:type()

    if child_type == 'field_identifier' and is_valid_field_identifier(child) then
      if is_top_level_field_identifier(child) then
        candidate = child
      end
    elseif child_type == 'identifier' and is_valid_function_call_identifier(child) then
      candidate = child
    end

    if candidate then
      local s_row, s_col, _, _ = candidate:range()
      if s_row > row or (s_row == row and s_col > col) then
        return candidate
      end
    end

    local descendant = find_next(child, row, col)
    if descendant then
      return descendant
    end
  end

  return nil
end

function Get_previous_func_call()
  local root = get_root_node()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
  local previous_node = find_previous(root, current_row, current_col)
  if previous_node then
    local res = vim.treesitter.get_node_text(previous_node, 0)
    return res
  end
end

local function get_next_func_call()
  local root = get_root_node()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
  local previous_node = find_next(root, current_row, current_col)
  if previous_node then
    local res = vim.treesitter.get_node_text(previous_node, 0)
    print(res)
    return res
  end
end

local function move_to_next_valid_identifier()
  local root = get_root_node()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
  local next_node = find_next(root, current_row, current_col)

  if next_node then
    local start_row, start_col, _, _ = next_node:range()
    -- Adjusting for Neovim's 1-indexed rows:
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  end
end

local function move_to_previous_valid_identifier()
  local root = get_root_node()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
  local previous_node = find_previous(root, current_row, current_col)

  if previous_node then
    local start_row, start_col, _, _ = previous_node:range()
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  end
end

vim.api.nvim_create_user_command('NextFuncCall', get_next_func_call, {})
vim.api.nvim_create_user_command('PrevFuncCall', Get_previous_func_call, {})
vim.keymap.set('n', ']f', move_to_next_valid_identifier, { desc = 'Next function call' })
vim.keymap.set('n', '[f', move_to_previous_valid_identifier, { desc = 'Previous function call' })
