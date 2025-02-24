local M = {}

function M.lsp_references_to_quickfix(line, col)
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
    for _, ref in ipairs(result) do
      local uri = ref.uri or ref.targetUri
      assert(uri, 'URI is nil')

      local filename = vim.uri_to_fname(uri)
      if filename and not filename:match '_test%.go$' then
        local range = ref.range or ref.targetSelectionRange
        assert(range, 'range is nil')
        assert(range.start, 'range.start is nil')

        local ref_lnum = range.start.line + 1
        local ref_col = range.start.character + 1
        table.insert(qflist, {
          filename = filename,
          lnum = ref_lnum,
          col = ref_col,
          text = filename .. ':' .. ref_lnum,
        })
      end
    end

    vim.fn.setqflist(qflist)
  end)
end

function M.lsp_references_nearest_function()
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
  M.lsp_references_to_quickfix(start_row + 1, start_col + 1) -- Adjust from 0-indexed to 1-indexed positions.
end

vim.api.nvim_create_user_command('LspReferencesFunc', M.lsp_references_nearest_function, {})

function M.toggle_quickfix()
  if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix == 1 then
    vim.cmd 'cclose'
  else
    vim.cmd 'copen'
  end
end

return M
