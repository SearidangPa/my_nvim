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
