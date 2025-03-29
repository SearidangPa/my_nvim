local M = {}
local util_find_func = require 'config.util_find_func'

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

function M.add_to_quickfix(qflist, filename, location, text)
  table.insert(qflist, {
    filename = filename,
    lnum = location.line,
    col = location.col,
    text = text,
  })
  return true
end

vim.api.nvim_create_user_command('LoadFuncDeclRef', M.lsp_ref_func_decl__nearest_func, {})
vim.keymap.set('n', '<leader>ld', M.lsp_ref_func_decl__nearest_func, { desc = '[L]oad ref [D]eclaration' })
