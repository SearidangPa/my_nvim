local M = {}

-- Helper function to get hover information for a reference position
function M.get_hover_info(uri, line, col, timeout)
  local params = {
    textDocument = { uri = uri },
    position = { line = line, character = col },
  }

  local response = vim.lsp.buf_request_sync(0, 'textDocument/hover', params, timeout or 1000)
  if response then
    for _, res in pairs(response) do
      if res.result and res.result.contents then
        -- Extract content from hover result
        return type(res.result.contents) == 'table' and (res.result.contents.value or res.result.contents[1].value) or tostring(res.result.contents)
      end
    end
  end
  return nil
end

-- Helper function to extract function declaration from hover content
function M.extract_function_decl(hover_content)
  if not hover_content then
    return nil
  end

  -- Parse out the function declaration (Go-specific)
  local func_decl = hover_content:match 'func%s+[^{]+'
  if func_decl then
    -- Get function name for symbol search
    local func_name = func_decl:match 'func%s+([^(]+)'
    if func_name then
      return {
        name = func_name,
        declaration = func_decl:gsub('\n', ' '):gsub('%s+', ' '):sub(1, 80),
      }
    end
  end
  return nil
end

-- Helper function to find function declaration location
function M.find_function_location(uri, func_info, timeout)
  if not func_info or not func_info.name then
    return nil
  end

  local func_params = {
    textDocument = { uri = uri },
    query = 'func ' .. func_info.name,
  }

  local symbols_response = vim.lsp.buf_request_sync(0, 'workspace/symbol', func_params, timeout or 1000)

  for _, sym_res in pairs(symbols_response or {}) do
    if sym_res.result then
      for _, symbol in ipairs(sym_res.result) do
        if symbol.location then
          -- Return the function declaration location
          return {
            line = symbol.location.range.start.line + 1, -- Convert to 1-indexed
            col = symbol.location.range.start.character + 1, -- Convert to 1-indexed
          }
        end
      end
    end
  end
  return nil
end

-- Helper to add a reference to quickfix list
function M.add_to_quickfix(qflist, filename, location, text)
  table.insert(qflist, {
    filename = filename,
    lnum = location.line,
    col = location.col,
    text = text,
  })
  return true
end

-- Main function to find enclosing function for a reference
function M.find_enclosing_function(uri, ref_line, ref_col, qflist, processed_funcs)
  local filename = vim.uri_to_fname(uri)
  if not filename or filename:match '_test%.go$' then
    return false
  end

  -- Use a unique key to identify this reference location
  local ref_key = filename .. ':' .. ref_line .. ':' .. ref_col

  -- Skip if we've already processed this reference
  if processed_funcs[ref_key] then
    return false
  end

  -- Get hover information at reference position
  local hover_content = M.get_hover_info(uri, ref_line, ref_col)

  -- Extract function declaration
  local func_info = M.extract_function_decl(hover_content)

  if func_info then
    -- Find function declaration location
    local location = M.find_function_location(uri, func_info)

    if location then
      -- Add to quickfix list
      M.add_to_quickfix(qflist, filename, location, func_info.declaration)
      processed_funcs[ref_key] = true
      return true
    end
  end

  -- Fallback: use reference location if function declaration not found
  M.add_to_quickfix(
    qflist,
    filename,
    { line = ref_line + 1, col = ref_col + 1 }, -- Convert to 1-indexed
    filename .. ':' .. (ref_line + 1) .. " (reference only - couldn't find function declaration)"
  )
  processed_funcs[ref_key] = true
  return true
end

-- Main function to process LSP references and create quickfix list
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
      print('Processing reference at line:', ref_line + 1, 'col:', ref_col + 1)

      -- Process this reference to find its enclosing function
      -- M.find_enclosing_function(uri, ref_line, ref_col, qflist, processed_funcs)
    end

    vim.fn.setqflist(qflist)
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
