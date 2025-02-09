local function get_root_node()
  local bufnr = vim.api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local parser = vim.treesitter.get_parser(bufnr, lang, {})
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(root, 'Tree root is nil')

  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local query = vim.treesitter.query.parse(
    lang,
    [[
      (function_declaration) @func_decl
    ]]
  )
  return root, query
end

local function find_next_func_decl_end(root, query, cursor_row)
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

local function find_next_func_decl_start(root, query, cursor_row)
  for _, node in query:iter_captures(root, 0, 0, -1) do
    if node then
      local s_row, _, _ = node:start()
      if s_row > cursor_row then
        return node
      end
    end
  end
  return nil
end

local function move_to_next_func_decl_start(opts)
  local count = vim.v.count
  if count == 0 then
    count = 1
  end
  local root, query = get_root_node()
  for _ = 1, count do
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
    local next_node = find_next_func_decl_start(root, query, current_row)

    if next_node then
      local start_row, start_col, end_row, end_col = next_node:range()
      vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
      current_row = start_row
    end
  end
end

local function move_to_next_func_decl_end(opts)
  local count = vim.v.count
  if count == 0 then
    count = 1
  end
  local root, query = get_root_node()
  for _ = 1, count do
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_row, current_col = cursor_pos[1] - 1, cursor_pos[2]
    local next_node = find_next_func_decl_end(root, query, current_row)

    if next_node then
      local start_row, start_col, end_row, end_col = next_node:range()
      vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
      current_row = end_row
    end
  end
end

local function prev_func_decl_start(root, query, cursor_row)
  local previous_node = nil
  for _, node in query:iter_captures(root, 0, 0, -1) do
    if node then
      if not previous_node then
        previous_node = node
      end

      local s_row, _, _ = node:start()
      if s_row >= cursor_row then
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

local function prev_func_decl_end(root, query, cursor_row)
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
  local root, query = get_root_node()
  for _ = 1, count do
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_row = cursor_pos[1] - 1
    local previous_node = prev_func_decl_start(root, query, current_row)
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
    local previous_node = prev_func_decl_end(root, query, current_row)
    if previous_node then
      local _, _, end_row, end_col = previous_node:range()
      vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
      current_row = end_row
    end
  end
end

vim.keymap.set('n', ']m', move_to_next_func_decl_start, { desc = 'Next Func Declaraion start' })
vim.keymap.set('n', '[m', move_to_prev_func_decl_start, { desc = 'Prev Func Declaraion start' })

vim.keymap.set('n', ']M', move_to_next_func_decl_end, { desc = 'Next Func Declaraion End' })
vim.keymap.set('n', '[M', move_to_prev_func_decl_end, { desc = 'Prev Func Declaraion End' })
