local M = {}
local util_find_func = require 'config.util_find_func'

function M.add_to_quickfix(qflist, filename, location, text)
  table.insert(qflist, {
    filename = filename,
    lnum = location.line,
    col = location.col,
    text = text,
  })
  return true
end

function M.find_enclosing_function(uri, ref_line, ref_col, qflist, processed_funcs)
  local filename = vim.uri_to_fname(uri)
  if not filename or filename:match '_test%.go$' then
    return false
  end

  -- Convert URI to buffer number
  local bufnr = vim.fn.bufadd(filename)
  vim.fn.bufload(bufnr)

  -- Find the nearest function declaration containing this reference
  local func_node = util_find_func.nearest_function_at_line(bufnr, ref_line)
  if not func_node then
    print('No enclosing function found for reference at line', ref_line + 1)
    return false
  end

  -- Extract function name and range
  local func_name = 'Unknown function'
  local func_range = { start_row = 0, end_row = 0, start_col = 0, end_col = 0 }

  -- Get the function name from identifier node
  for child in func_node:iter_children() do
    if child:type() == 'identifier' or child:type() == 'field_identifier' or child:type() == 'name' then
      func_name = vim.treesitter.get_node_text(child, bufnr)
      func_range.start_row, func_range.start_col, func_range.end_row, func_range.end_col = func_node:range()
      break
    end
  end

  -- Create a unique key to track processed functions to avoid duplicates
  local func_key = filename .. ':' .. func_name .. ':' .. func_range.start_row

  -- Skip if we've already processed this function
  if processed_funcs[func_key] then
    return false
  end

  -- Mark function as processed
  processed_funcs[func_key] = true

  -- Add the function to the quickfix list
  local text = 'Function: ' .. func_name
  local location = {
    line = func_range.start_row + 1, -- Convert to 1-based line numbers
    col = func_range.start_col + 1, -- Convert to 1-based column numbers
  }

  return M.add_to_quickfix(qflist, filename, location, text)
end

function M.lsp_ref_func_decl(line, col)
  assert(line, 'line is nil')
  assert(col, 'col is nil')
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
    position = { line = line - 1, character = col - 1 },
    context = { includeDeclaration = false },
  }
  vim.lsp.buf_request(0, 'textDocument/references', params, function(err, result, _, _)
    assert(result, 'result is nil')
    assert(not err, 'err is not nil')
    local qflist = {}
    local processed_funcs = {} -- Track function declarations we've already added
    for _, ref in ipairs(result) do
      local uri = ref.uri or ref.targetUri
      assert(uri, 'URI is nil')
      local range = ref.range or ref.targetSelectionRange
      assert(range, 'range is nil')
      assert(range.start, 'range.start is nil')
      local ref_line = range.start.line
      local ref_col = range.start.character
      M.find_enclosing_function(uri, ref_line, ref_col, qflist, processed_funcs)
    end
    vim.fn.setqflist(qflist)
    vim.cmd 'copen' -- Open the quickfix window after everything is processed
  end)
end

function M.lsp_ref_func_decl__nearest_func()
  require 'config.util_find_func'
  local func_node = Nearest_func_node()
  assert(func_node, 'No function found')
  local func_identifier
  for child in func_node:iter_children() do
    if child:type() == 'identifier' or child:type() == 'name' then
      func_identifier = child
    end
  end
  local start_row, start_col = func_identifier:range()
  assert(start_row, 'start_row is nil')
  assert(start_col, 'start_col is nil')
  M.lsp_ref_func_decl(start_row + 1, start_col + 1) -- Adjust from 0-indexed to 1-indexed positions.
  vim.cmd 'copen'
end

vim.api.nvim_create_user_command('LoadFuncDeclRef', M.lsp_ref_func_decl__nearest_func, {})
vim.keymap.set('n', '<leader>ld', M.lsp_ref_func_decl__nearest_func, { noremap = true, silent = true })
