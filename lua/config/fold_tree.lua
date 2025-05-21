local folded_hl = vim.api.nvim_get_hl(0, { name = 'Folded' })
local statusline_hl = vim.api.nvim_get_hl(0, { name = 'StatusLine' })
local new_hl = {
  bg = statusline_hl.bg,
  fg = folded_hl.fg,
  bold = folded_hl.bold,
  italic = folded_hl.italic,
}
vim.api.nvim_set_hl(0, 'Folded', new_hl)

vim.opt.foldtext = [[luaeval('Highlighted_fold_text')()]]

local function highlight_line_with_treesitter(line, pos)
  assert(vim.treesitter, 'Treesitter is not available')
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  if not lang then
    return {}, 0
  end
  local parser = vim.treesitter.get_parser(0, lang)
  assert(parser, 'Parser not found')
  local query = vim.treesitter.query.get(parser:lang(), 'highlights')
  assert(query, 'Query not found')
  if query == nil then
    print 'No highlights query found'
    return {}, 0
  end
  local tree = parser:parse({ pos - 1, pos })[1]
  local result = {}
  local line_pos = 0
  local prev_range = nil
  for id, node in query:iter_captures(tree:root(), 0, pos - 1, pos) do
    local name = query.captures[id]
    local start_row, start_col, end_row, end_col = node:range()
    if start_row == pos - 1 and end_row == pos - 1 then
      local range = { start_col, end_col }
      if start_col > line_pos then
        table.insert(result, { line:sub(line_pos + 1, start_col), 'Folded' })
      end
      line_pos = end_col
      local text = vim.treesitter.get_node_text(node, 0)
      if prev_range ~= nil and range[1] == prev_range[1] and range[2] == prev_range[2] then
        result[#result] = { text, '@' .. name }
      else
        table.insert(result, { text, '@' .. name })
      end
      prev_range = range
    end
  end
  return result, line_pos
end

function Highlighted_fold_text()
  local pos = vim.v.foldstart
  local end_pos = vim.v.foldend
  local line_count = end_pos - pos + 1
  local line = vim.api.nvim_buf_get_lines(0, pos - 1, pos, false)[1]
  local result, line_pos = highlight_line_with_treesitter(line, pos)
  if #result == 0 then
    return { { '\t\t[' .. line_count .. ' lines] ', 'Folded' } }
  end
  table.insert(result, { '\t\t[' .. line_count .. ' lines] ', 'Folded' })
  if line_pos < #line then
    table.insert(result, { line:sub(line_pos + 1), 'Folded' })
  end
  return result
end

-- ============= fold nodes functions =============

local function fold_node_recursively(node)
  local start_row, _, end_row, _ = node:range()
  start_row = start_row + 1
  end_row = end_row

  if start_row <= end_row then
    vim.cmd(string.format('%d,%dfold', start_row, end_row))
  end

  for child in node:iter_children() do
    fold_node_recursively(child)
  end
end

local function fold_captured_nodes_recursively(query)
  local bufnr = vim.api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local parser = vim.treesitter.get_parser(bufnr, lang, {})
  assert(parser, 'Parser not found')
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(root, 'Tree root is nil')

  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    if node then
      fold_node_recursively(node)
    end
  end
end

local function fold_err_if_node(query, root, bufnr)
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
  assert(parser, 'Parser not found')
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(root, 'Tree root is nil')

  fold_err_if_node(query, root, bufnr)
end

local function fold_switch()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  assert(lang, 'Language is nil')
  local query = vim.treesitter.query.parse(
    lang,
    [[
    (expression_case) @expr_case
    (type_case) @type_case
    (default_case) @default_case
  ]]
  )
  fold_captured_nodes_recursively(query)
end

local function fold_comm()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  assert(lang, 'Language is nil')
  local query = vim.treesitter.query.parse(
    lang,
    [[
      (communication_case) @comm_case
      (default_case) @default_case
    ]]
  )
  fold_captured_nodes_recursively(query)
end

local function fold_Func()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  assert(lang, 'Language is nil')
  local query = vim.treesitter.query.parse(
    lang,
    [[
      (function_declaration) @func_decl
      (method_declaration) @method_decl
    ]]
  )
  fold_captured_nodes_recursively(query)
end

local function fold_Type_Decl()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  assert(lang, 'Language is nil')
  local query = vim.treesitter.query.parse(
    lang,
    [[
      (type_declaration) @type_decl
    ]]
  )
  fold_captured_nodes_recursively(query)
end

local function fold_if()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  assert(lang, 'Language is nil')
  local query = vim.treesitter.query.parse(
    lang,
    [[
      (if_statement) @comm_case
    ]]
  )
  fold_captured_nodes_recursively(query)
end

local function fold_short_var_decl()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  assert(lang, 'Language is nil')
  local query = vim.treesitter.query.parse(
    lang,
    [[
      (short_var_declaration ) @short_var_decl
    ]]
  )
  fold_captured_nodes_recursively(query)
end

local function fold_return()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  assert(lang, 'Language is nil')
  local query = vim.treesitter.query.parse(
    lang,
    [[
      (return_statement) @return_statement
    ]]
  )
  fold_captured_nodes_recursively(query)
end

local function fold_tree()
  fold_switch()
  fold_comm()
  fold_if()
  fold_short_var_decl()
  fold_return()
  fold_Type_Decl()
end

-- ============= User commands =============
local user_cmd = vim.api.nvim_create_user_command
user_cmd('FoldErr', fold_err, {})
user_cmd('FoldCase', function()
  fold_switch()
  fold_comm()
end, {})

user_cmd('FoldTree', fold_tree, {})
user_cmd('FoldFunc', fold_Func, {})
user_cmd('FoldSwitch', fold_switch, {})
user_cmd('FoldComm', fold_comm, {})
user_cmd('FoldTypeDecl', fold_Type_Decl, {})
user_cmd('FoldShortVarDecl', fold_short_var_decl, {})
user_cmd('FoldIf', fold_if, {})
user_cmd('FoldReturn', fold_return, {})
