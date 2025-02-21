local function lsp_references_to_quickfix(line, col)
  if not line or not col then
    print 'Line and column are required.'
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
    position = { line = line - 1, character = col - 1 },
    context = { includeDeclaration = false },
  }

  vim.lsp.buf_request(0, 'textDocument/references', params, function(err, result, _, _)
    if err or not result then
      print 'No references found or an error occurred.'
      return
    end

    local qflist = {}
    for _, ref in ipairs(result) do
      local uri = ref.uri or ref.targetUri
      if uri then
        local filename = vim.uri_to_fname(uri)
        if filename and not filename:match '_test%.go$' then
          local range = ref.range or ref.targetSelectionRange
          if range and range.start then
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
      end
    end

    vim.fn.setqflist(qflist)
    vim.cmd 'copen'
  end)
end

local function lsp_references_nearest_function()
  local util = require 'config.util_find_func'
  local func_node = util.Nearest_func_node()
  if not func_node then
    print 'No function node found.'
    return
  end
  local start_row, start_col = func_node:range()
  if not start_row or not start_col then
    print 'Invalid function node range.'
    return
  end
  -- Adjust from 0-indexed to 1-indexed positions.
  lsp_references_to_quickfix(start_row + 1, start_col + 1)
end

vim.api.nvim_create_user_command('LspReferencesFunc', lsp_references_nearest_function, {})
