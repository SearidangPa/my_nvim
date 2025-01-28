local function fold_node_recursively(node)
  local start_row, _, end_row, _ = node:range()
  start_row = start_row + 1
  end_row = end_row + 1

  if start_row <= end_row then
    vim.cmd(string.format('%d,%dfold', start_row, end_row))
  end

  for child in node:iter_children() do
    fold_node_recursively(child)
  end
end

local function fold_captured_nodes_recursively(query)
  local bufnr = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr, 'go', {})
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(root, 'Tree root is nil')

  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    if node then
      fold_node_recursively(node)
    end
  end
end

local function fold_switch()
  local query = vim.treesitter.query.parse(
    'go',
    [[
    (expression_case) @expr_case
    (type_case) @type_case
    (default_case) @default_case
  ]]
  )
  fold_captured_nodes_recursively(query)
end

local function fold_comm()
  local query = vim.treesitter.query.parse(
    'go',
    [[
      (communication_case) @comm_case
      (default_case) @default_case
    ]]
  )
  fold_captured_nodes_recursively(query)
end

local function fold_if()
  local query = vim.treesitter.query.parse(
    'go',
    [[
      (if_statement) @comm_case
    ]]
  )
  fold_captured_nodes_recursively(query)
end

local function fold_short_var_decl()
  local query = vim.treesitter.query.parse(
    'go',
    [[
      (short_var_declaration ) @short_var_decl
    ]]
  )
  fold_captured_nodes_recursively(query)
end

local function fold_return()
  local query = vim.treesitter.query.parse(
    'go',
    [[
      (return_statement) @return_statement
    ]]
  )
  fold_captured_nodes_recursively(query)
end

-- ============= User commands =============

vim.api.nvim_create_user_command('FoldIf', function()
  fold_if()
end, {})

vim.api.nvim_create_user_command('FoldShortVarDecl', function()
  fold_short_var_decl()
end, {})

vim.api.nvim_create_user_command('FoldReturn', function()
  fold_return()
end, {})

vim.api.nvim_create_user_command('FoldSwitch', fold_switch, {})

-- =============== Combined ===============

vim.api.nvim_create_user_command('FoldCase', function()
  fold_switch()
  fold_comm()
end, {})

local function fold_all()
  fold_switch()
  fold_comm()
  fold_if()
  fold_short_var_decl()
  fold_return()
end

vim.api.nvim_create_user_command('FoldAll', fold_all, {})

-- ============= Key mappings =============
vim.keymap.set('n', '<leader>fs', fold_switch, { desc = '[F]old [S]witch' })
vim.keymap.set('n', '<leader>fc', fold_comm, { desc = '[F]old [C]ommunication' })
vim.keymap.set('n', '<leader>fi', fold_if, { desc = '[F]old [I]f' })
vim.keymap.set('n', '<leader>fv', fold_short_var_decl, { desc = '[F]old [V]ariable declaration' })
vim.keymap.set('n', '<leader>fr', fold_return, { desc = '[F]old [R]eturn' })
vim.keymap.set('n', '<leader>fa', fold_all, { desc = '[F]old [A]ll' })
