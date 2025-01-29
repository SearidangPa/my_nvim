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
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local parser = vim.treesitter.get_parser(bufnr, lang, {})
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
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local query = vim.treesitter.query.parse(
    lang,
    [[
    (expression_case) @expr_case
    (type_case) @type_case
    (default_case) @default_case
  ]]
  )
  Fold_captured_nodes_recursively(query)
end

function Fold_comm()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local query = vim.treesitter.query.parse(
    lang,
    [[
      (communication_case) @comm_case
      (default_case) @default_case
    ]]
  )
  Fold_captured_nodes_recursively(query)
end

function Fold_if()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local query = vim.treesitter.query.parse(
    lang,
    [[
      (if_statement) @comm_case
    ]]
  )
  Fold_captured_nodes_recursively(query)
end

function Fold_short_var_decl()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local query = vim.treesitter.query.parse(
    lang,
    [[
      (short_var_declaration ) @short_var_decl
    ]]
  )
  Fold_captured_nodes_recursively(query)
end

function Fold_return()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local query = vim.treesitter.query.parse(
    lang,
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
