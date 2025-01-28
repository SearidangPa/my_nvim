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
          vim.cmd 'normal! zc'
        end
      end
    end
  end
end

vim.api.nvim_create_user_command('FoldErrBlocks', function()
  fold_err_blocks(vim.api.nvim_get_current_buf())
end, {})

local function fold_node(node)
  local start_row, _, end_row, _ = node:range()
  start_row = start_row + 1
  end_row = end_row

  -- print(string.format('Folding from %d to %d', start_row, end_row))
  vim.api.nvim_win_set_cursor(0, { start_row, 0 })
  vim.cmd 'normal! zc'
end

local function fold_captured_nodes(bufnr, query)
  local parser = vim.treesitter.get_parser(bufnr, 'go', {})
  local tree = parser:parse()[1]
  local root = tree:root()
  assert(root, 'Tree root is nil')

  local current_cursor = vim.api.nvim_win_get_cursor(0)
  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    if node then
      fold_node(node)
    end
  end

  vim.api.nvim_win_set_cursor(0, current_cursor)
end

vim.api.nvim_create_user_command('FoldSwitchCase', function()
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

vim.api.nvim_create_user_command('FoldSelectCase', function()
  local query = vim.treesitter.query.parse(
    'go',
    [[
    (communication_case) @comm_case
  ]]
  )
  vim.api.nvim_set_option_value('foldmethod', 'manual', { scope = 'local' })
  fold_captured_nodes(vim.api.nvim_get_current_buf(), query)
end, {})
function HighlightedFoldtext()
  local pos = vim.v.foldstart
  local line = vim.api.nvim_buf_get_lines(0, pos - 1, pos, false)[1]
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local parser = vim.treesitter.get_parser(0, lang)
  local query = vim.treesitter.query.get(parser:lang(), 'highlights')

  if query == nil then
    return vim.fn.foldtext()
  end

  local tree = parser:parse({ pos - 1, pos })[1]
  local result = {}

  local line_pos = 0

  local prev_range = nil

  for id, node, _ in query:iter_captures(tree:root(), 0, pos - 1, pos) do
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

  return result
end

local bg = vim.api.nvim_get_hl(0, { name = 'StatusLine' }).bg
local hl = vim.api.nvim_get_hl(0, { name = 'Folded' })
hl.bg = bg
vim.api.nvim_set_hl(0, 'Folded', hl)

vim.opt.foldtext = [[luaeval('HighlightedFoldtext')()]]
