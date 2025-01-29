local bg = vim.api.nvim_get_hl(0, { name = 'StatusLine' }).bg
local hl = vim.api.nvim_get_hl(0, { name = 'Folded' })
hl.bg = bg
vim.api.nvim_set_hl(0, 'Folded', hl)
vim.opt.foldtext = [[luaeval('HighlightedFoldtext')()]]

function HighlightedFoldtext()
  local pos = vim.v.foldstart
  local end_pos = vim.v.foldend
  local line_count = end_pos - pos + 1
  local line = vim.api.nvim_buf_get_lines(0, pos - 1, pos, false)[1]
  local result, line_pos = Highlight_Line_With_Treesitter(line, pos)

  table.insert(result, #result + 1, { '\t\t[' .. line_count .. ' lines] ', 'Folded' })
  if line_pos < #line then
    table.insert(result, { line:sub(line_pos + 1), 'Folded' })
  end
  return result
end

-- ============= fold nodes functions =============

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

function Fold_errIf_node(query, root, bufnr)
  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    if not node then
      return
    end

    local left_text = vim.treesitter.get_node_text(node, bufnr)

    if not string.find(left_text, 'err') then
      goto continue
    end

    local current_node = node:parent()
    while current_node and current_node:type() ~= 'if_statement' do
      current_node = current_node:parent()
    end

    if current_node and current_node:type() == 'if_statement' then
      local start_row, _, end_row, _ = current_node:range()
      start_row = start_row + 1
      end_row = end_row

      if start_row <= end_row then
        vim.cmd(string.format('%d,%dfold', start_row, end_row + 1))
      end
    end

    ::continue::
  end
end

-- ============= Tree-sitter queries =============

local function fold_err()
  local bufnr = vim.api.nvim_get_current_buf()
  local query = vim.treesitter.query.parse(
    'go',
    [[
    (if_statement
      condition: (binary_expression
        left: (identifier) @left
        right: (nil) @right))
    (if_statement
      condition: (binary_expression
        left: (identifier) @left
        right: (selector_expression) @right))
  ]]
  )
  local parser = vim.treesitter.get_parser(bufnr, 'go', {})
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(root, 'Tree root is nil')

  Fold_errIf_node(query, root, bufnr)
end

vim.api.nvim_create_user_command('FoldErr', fold_err, {})
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

function Fold_Func()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local query = vim.treesitter.query.parse(
    lang,
    [[
      (function_declaration ) @func_decl
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

local map = vim.keymap.set
-- ============= Fold =============
map('n', '<leader>fs', Fold_switch, { desc = '[F]old [S]witch' })
map('n', '<leader>fc', Fold_comm, { desc = '[F]old [C]ommunication' })
map('n', '<leader>fi', Fold_if, { desc = '[F]old [I]f' })
map('n', '<leader>fv', Fold_short_var_decl, { desc = '[F]old [V]ariable declaration' })
map('n', '<leader>fr', Fold_return, { desc = '[F]old [R]eturn' })
map('n', '<leader>fa', Fold_all, { desc = '[F]old [A]ll' })
map('n', '<leader>fe', Fold_errIf_node, { desc = '[F]old [E]rror block' })
map('n', '<leader>ff', Fold_Func, { desc = '[F]old [F]unction' })
