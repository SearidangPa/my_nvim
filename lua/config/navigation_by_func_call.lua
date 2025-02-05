local function get_root_node()
  local buf_nr = vim.api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local parser = vim.treesitter.get_parser(buf_nr, lang)
  local tree = parser:parse()[1]
  local root = tree:root()
  return root
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

local function find_next(node, row, col)
  for child in node:iter_children() do
    if
      (child:type() == 'field_identifier' and is_valid_field_identifier(child))
      or (child:type() == 'identifier' and is_valid_function_call_identifier(child))
    then
      local start_row, start_col, _, _ = child:range()
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

local function move_to_next_valid_identifier()
  local root = get_root_node()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
  local next_node = find_next(root, current_row, current_col)

  if next_node then
    local start_row, start_col, _, _ = next_node:range()
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  end
end

function Find_previous(node, row, col)
  local previous_node = nil

  local function search(n)
    for child in n:iter_children() do
      search(child)
      if
        (child:type() == 'field_identifier' and is_valid_field_identifier(child))
        or (child:type() == 'identifier' and is_valid_function_call_identifier(child))
      then
        local start_row, start_col, _, _ = child:range()
        if start_row < row or (start_row == row and start_col < col) then
          if not previous_node then
            previous_node = child
          else
            local prev_row, prev_col, _, _ = previous_node:range()
            if start_row > prev_row or (start_row == prev_row and start_col > prev_col) then
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

local function move_to_previous_valid_identifier()
  local root = get_root_node()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
  local previous_node = Find_previous(root, current_row, current_col)
  print(previous_node)

  if previous_node then
    local start_row, start_col, _, _ = previous_node:range()
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  end
end

vim.keymap.set('n', ']f', move_to_next_valid_identifier, { desc = 'Next function call' })
vim.keymap.set('n', '[f', move_to_previous_valid_identifier, { desc = 'Previous function call' })
