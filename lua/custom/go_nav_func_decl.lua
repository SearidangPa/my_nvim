local function get_root_node(opts)
  local is_func_start = opts and opts.is_func_start or false

  local bufnr = vim.api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local parser = vim.treesitter.get_parser(bufnr, lang, {})
  assert(parser, 'Parser is nil')
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(root, 'Tree root is nil')

  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)

  local query
  if lang == 'lua' then
    if is_func_start then
      query = vim.treesitter.query.parse(
        lang,
        [[
      (function_declaration
        name: (identifier) @func_decl_start
      )
    ]]
      )
      return root, query
    else
      query = vim.treesitter.query.parse(
        lang,
        [[
      (function_declaration
        name: (identifier) @func_decl_start
      ) @func_decl_node
    ]]
      )
      return root, query
    end
  end

  if is_func_start then
    query = vim.treesitter.query.parse(
      lang,
      [[
      (function_declaration
        name: (identifier) @func_decl_start
      )
      (method_declaration
      name: (field_identifier) @func_decl_start
      )
    ]]
    )
  else
    query = vim.treesitter.query.parse(
      lang,
      [[
      (function_declaration
        name: (identifier) @func_decl_start
      ) @func_decl_node
      (method_declaration
      name: (field_identifier) @func_decl_start
      ) @func_decl_node
    ]]
    )
  end
  return root, query
end

local function find_next_func_decl_end(root, query, cursor_row, cursor_col)
  for _, node in query:iter_captures(root, 0, 0, -1) do
    if node then
      local _, _, e_row, _ = node:range()
      if e_row > cursor_row then
        return node
      end
    end
  end
  return nil
end

local function find_next_func_decl_start(root, query, cursor_row, cursor_col)
  for _, node in query:iter_captures(root, 0, 0, -1) do
    if node then
      local s_row, s_col, _ = node:start()
      if s_row > cursor_row or (s_row == cursor_row and s_col > cursor_col) then
        return node
      end
    end
  end
  return nil
end

local function move_to_next_func_decl_start()
  local count = vim.v.count
  if count == 0 then
    count = 1
  end
  local root, query = get_root_node { is_func_start = true }
  for _ = 1, count do
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
    local next_node = find_next_func_decl_start(root, query, current_row, current_col)

    if next_node then
      local start_row, start_col, end_row, end_col = next_node:range()
      vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
      current_row = start_row
    end
  end
end

local function move_to_next_func_decl_end()
  local count = vim.v.count
  if count == 0 then
    count = 1
  end
  local root, query = get_root_node()
  for _ = 1, count do
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
    local next_node = find_next_func_decl_end(root, query, current_row, current_col)

    if next_node then
      local start_row, start_col, end_row, end_col = next_node:range()
      vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
      current_row = end_row
    end
  end
end

local function prev_func_decl_start(root, query, cursor_row, cursor_col)
  local previous_node = nil
  for id, node, metadata, match in query:iter_captures(root, 0, 0, -1) do
    if node then
      if not previous_node then
        previous_node = node
      end

      local s_row, s_col, _ = node:start()
      if s_row > cursor_row or (s_row == cursor_row and s_col >= cursor_col) then
        break
      end

      local prev_s_row, _, _ = previous_node:start()
      if s_row > prev_s_row then
        previous_node = node
      end
    end
  end
  return previous_node
end

local function prev_func_decl_end(root, query, cursor_row, cursor_col)
  local previous_node = nil
  for _, node in query:iter_captures(root, 0, 0, -1) do
    if node then
      if not previous_node then
        previous_node = node
      end

      local _, _, e_row, _ = node:range()
      if e_row >= cursor_row then
        break
      end

      local _, _, prev_s_row, _ = previous_node:range()
      if e_row > prev_s_row then
        previous_node = node
      end
    end
  end
  return previous_node
end

local function move_to_prev_func_decl_start()
  local count = vim.v.count
  if count == 0 then
    count = 1
  end
  local root, query = get_root_node { is_func_start = true }
  for _ = 1, count do
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_row = cursor_pos[1] - 1
    local current_col = cursor_pos[2]
    local previous_node = prev_func_decl_start(root, query, current_row, current_col)
    if previous_node then
      local start_row, start_col, _, _ = previous_node:range()
      vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
      current_row = start_row
    end
  end
end

local function move_to_prev_func_decl_end()
  local count = vim.v.count
  if count == 0 then
    count = 1
  end
  local root, query = get_root_node()
  for _ = 1, count do
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_row = cursor_pos[1] - 1
    local current_col = cursor_pos[2]
    local previous_node = prev_func_decl_end(root, query, current_row, current_col)
    if previous_node then
      local _, _, end_row, end_col = previous_node:range()
      vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
      current_row = end_row
    end
  end
end

local map = vim.keymap.set

vim.keymap.set('n', ']m', move_to_next_func_decl_start, { desc = 'Next Func Declaraion start' })
vim.keymap.set('n', '[m', move_to_prev_func_decl_start, { desc = 'Prev Func Declaraion start' })

vim.keymap.set('n', ']M', move_to_next_func_decl_end, { desc = 'Next Func Declaraion End' })
vim.keymap.set('n', '[M', move_to_prev_func_decl_end, { desc = 'Prev Func Declaraion End' })
