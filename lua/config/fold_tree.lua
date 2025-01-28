function Fold_node_recursively(node)
  local start_row, _, end_row, _ = node:range()
  start_row = start_row + 1
  end_row = end_row + 1

  if start_row <= end_row then
    vim.cmd(string.format('%d,%dfold', start_row, end_row))
  end

  for child in node:iter_children() do
    Fold_node_recursively(child)
  end
end

function Fold_captured_nodes_recursively(query)
  local bufnr = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr, 'go', {})
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(root, 'Tree root is nil')

  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    if node then
      Fold_node_recursively(node)
    end
  end
end

function Fold_switch()
  local query = vim.treesitter.query.parse(
    'go',
    [[
    (expression_case) @expr_case
    (type_case) @type_case
    (default_case) @default_case
  ]]
  )
  Fold_captured_nodes_recursively(query)
end

function Fold_comm()
  local query = vim.treesitter.query.parse(
    'go',
    [[
      (communication_case) @comm_case
      (default_case) @default_case
    ]]
  )
  Fold_captured_nodes_recursively(query)
end

function Fold_if()
  local query = vim.treesitter.query.parse(
    'go',
    [[
      (if_statement) @comm_case
    ]]
  )
  Fold_captured_nodes_recursively(query)
end

function Fold_short_var_decl()
  local query = vim.treesitter.query.parse(
    'go',
    [[
      (short_var_declaration ) @short_var_decl
    ]]
  )
  Fold_captured_nodes_recursively(query)
end

function Fold_return()
  local query = vim.treesitter.query.parse(
    'go',
    [[
      (return_statement) @return_statement
    ]]
  )
  Fold_captured_nodes_recursively(query)
end

-- ============= User commands =============

vim.api.nvim_create_user_command('FoldIf', function()
  Fold_if()
end, {})

vim.api.nvim_create_user_command('FoldShortVarDecl', function()
  Fold_short_var_decl()
end, {})

vim.api.nvim_create_user_command('FoldReturn', function()
  Fold_return()
end, {})

vim.api.nvim_create_user_command('FoldSwitch', Fold_switch, {})

-- =============== Combined ===============

vim.api.nvim_create_user_command('FoldCase', function()
  Fold_switch()
  Fold_comm()
end, {})

function Fold_all()
  Fold_switch()
  Fold_comm()
  Fold_if()
  Fold_short_var_decl()
  Fold_return()
end

vim.api.nvim_create_user_command('FoldAll', Fold_all, {})
