local function fold_err_blocks(bufnr)
  local query = vim.treesitter.query.parse(
    'go',
    [[
    (if_statement
      condition: (binary_expression
        left: (identifier) @left
        right: (nil) @right))
  ]]
  )
  local parser = vim.treesitter.get_parser(bufnr, 'go', {})
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(root, 'Tree root is nil')

  local current_cusror = vim.api.nvim_win_get_cursor(0)
  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    if not node then
      return
    end

    local left_text = vim.treesitter.get_node_text(node, bufnr)
    if left_text == 'err' then
      local current_node = node:parent()
      while current_node and current_node:type() ~= 'if_statement' do
        current_node = current_node:parent()
      end

      if current_node and current_node:type() == 'if_statement' then
        local start_row, _, end_row, _ = current_node:range()
        start_row = start_row + 1
        end_row = end_row

        if start_row <= end_row then
          vim.api.nvim_win_set_cursor(0, { start_row, 0 })
          vim.cmd 'normal! za'
        end
      end
    end
  end

  vim.api.nvim_win_set_cursor(0, current_cusror)
end

vim.api.nvim_create_user_command('FoldErrBlocks', function()
  fold_err_blocks(vim.api.nvim_get_current_buf())
end, {})

local function fold_node(node)
  local start_row, _, end_row, _ = node:range()
  start_row = start_row + 1
  end_row = end_row

  if start_row <= end_row then
    vim.cmd(string.format('%d,%dfold', start_row, end_row))
  end
end

local function fold_node_recursively(node, bufnr)
  -- Fold the current node
  fold_node(node)

  for child in node:iter_children() do
    fold_node_recursively(child, bufnr)
  end
end

local function fold_captured_nodes(bufnr, query)
  local parser = vim.treesitter.get_parser(bufnr, 'go', {})
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(root, 'Tree root is nil')

  local current_cursor = vim.api.nvim_win_get_cursor(0)
  local folded_nodes = {}

  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    if node then
      fold_node_recursively(node, bufnr)
      table.insert(folded_nodes, node)
    end
  end

  vim.api.nvim_win_set_cursor(0, current_cursor)
end

vim.api.nvim_create_user_command('FoldSwitch', function()
  local query = vim.treesitter.query.parse(
    'go',
    [[
    (expression_case) @expr_case
    (type_case) @type_case
    (default_case) @default_case
  ]]
  )
  fold_captured_nodes(vim.api.nvim_get_current_buf(), query)
end, {})
