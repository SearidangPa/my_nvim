local ignore_list = {
  NoError = true,
  Error = true,
  Errorf = true,
  Info = true,
  Infof = true,
  Warn = true,
  Debug = true,
  Fatal = true,
  Fatalf = true,
  Wrap = true,
  Wrapf = true,
  WithField = true,
  WithFields = true,
}

local function get_root_node()
  local buf_nr = vim.api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local parser = vim.treesitter.get_parser(buf_nr, lang)
  assert(parser, 'No parser found for this buffer')
  local tree = parser:parse()[1]
  local root = tree:root()
  return root
end

local function call_expr_statement(field_identifier_parent)
  local selector_expression_parent = field_identifier_parent:parent()
  if selector_expression_parent and selector_expression_parent:type() ~= 'call_expression' then
    return false
  end

  local call_expression_parent = selector_expression_parent:parent()
  if call_expression_parent and call_expression_parent:type() == 'expression_statement' then
    return true
  end
  if call_expression_parent and call_expression_parent:type() == 'go_statement' then
    return true
  end
  return false
end

local function select_call_expr_statement(node)
  local field_identifier_parent = node:parent()
  if not field_identifier_parent then
    return false
  end
  if field_identifier_parent:type() ~= 'selector_expression' then
    return false
  end
  return call_expr_statement(field_identifier_parent)
end

local function ignore(node)
  local text = vim.treesitter.get_node_text(node, 0)
  if not text then
    return false
  end

  if ignore_list[text] then
    return true
  end
  return false
end

local function find_previous_expr_statement(node, row, col)
  local previous_node = nil

  local function search(n)
    for child in n:iter_children() do
      search(child)

      local candidate = false
      if child:type() == 'field_identifier' and select_call_expr_statement(child) then
        candidate = not ignore(child)
      elseif child:type() == 'identifier' and call_expr_statement(child) then
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

local function find_next_expr_statement(node, row, col)
  for child in node:iter_children() do
    local candidate = nil

    if child:type() == 'field_identifier' and select_call_expr_statement(child) then
      if not ignore(child) then
        candidate = child
      end
    elseif child:type() == 'identifier' and call_expr_statement(child) then
      candidate = child
    end

    if candidate then
      local s_row, s_col, _, _ = candidate:range()
      if s_row > row or (s_row == row and s_col > col) then
        return candidate
      end
    end

    local descendant = find_next_expr_statement(child, row, col)
    if descendant then
      return descendant
    end
  end

  return nil
end

local function move_to_next_expr_statement()
  local count = vim.v.count
  if count == 0 then
    count = 1
  end
  local root = get_root_node()
  for _ = 1, count do
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
    local next_node = find_next_expr_statement(root, current_row, current_col)

    if next_node then
      local start_row, start_col, _, _ = next_node:range()
      vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    end
  end
end

local function move_to_previous_expr_statement()
  local count = vim.v.count
  if count == 0 then
    count = 1
  end
  local root = get_root_node()
  for _ = 1, count do
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
    local previous_node = find_previous_expr_statement(root, current_row, current_col)

    if previous_node then
      local start_row, start_col, _, _ = previous_node:range()
      vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    end
  end
end

vim.keymap.set('n', ']e', move_to_next_expr_statement, { desc = 'Next Expression' })
vim.keymap.set('n', '[e', move_to_previous_expr_statement, { desc = 'Previous Expression' })
