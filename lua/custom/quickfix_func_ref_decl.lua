local M = {}
local util_find_func = require 'config.util_find_func'

---@type qfItem[]
M.qflist = {}

M.processed_funcs = {} -- Track function declarations we've already added

---@type qfItem[]
M.new_func_decls = {} -- Track recent function declarations
M.last_func_decls = {} -- Track last function declarations

---@class qfItem
---@field filename string
---@field lnum number
---@field col number
---@field text string

function M.add_to_quickfix(qflist, filename, location, text)
  table.insert(qflist, {
    filename = filename,
    lnum = location.line,
    col = location.col,
    text = text,
  })
  table.insert(M.new_func_decls, {
    filename = filename,
    lnum = location.line,
    col = location.col,
    text = text,
  })
  return true
end

function M.find_enclosing_function(uri, ref_line)
  local filename = vim.uri_to_fname(uri)
  if not filename or filename:match '_test%.go$' then
    return nil
  end

  -- Convert URI to buffer number and load the buffer
  local bufnr = vim.fn.bufadd(filename)
  vim.fn.bufload(bufnr)

  -- Find the nearest function declaration at the reference line
  local func_node = util_find_func.nearest_function_at_line(bufnr, ref_line)
  if not func_node then
    print('No enclosing function found for reference at line', ref_line + 1)
    return nil
  end

  local func_name = 'Unknown function'
  local func_range = { start_row = 0, end_row = 0, start_col = 0, end_col = 0 }

  local func_identifier
  for child in func_node:iter_children() do
    if child:type() == 'identifier' or child:type() == 'field_identifier' or child:type() == 'name' then
      func_identifier = child
      break
    end
  end
  func_name = vim.treesitter.get_node_text(func_identifier, bufnr)
  func_range.start_row, func_range.start_col, func_range.end_row, func_range.end_col = func_identifier:range()

  local func_key = filename .. ':' .. func_name .. ':' .. func_range.start_row

  if M.processed_funcs[func_key] then
    return nil
  end

  M.processed_funcs[func_key] = true

  -- Get the complete function signature from the line
  local lines = vim.api.nvim_buf_get_lines(bufnr, func_range.start_row, func_range.start_row + 1, false)
  local signature = lines[1]
  local text = signature:gsub('^%s+', '') -- Remove leading whitespace

  local location = {
    line = func_range.start_row + 1, -- Convert from 0-indexed to 1-indexed
    col = func_range.start_col + 1,
  }
  return {
    filename = filename,
    location = location,
    text = text,
    func_name = func_name,
  }
end

function M.lsp_ref_func_decl(bufnr, line, col)
  assert(line, 'line is nil')
  assert(col, 'col is nil')
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = line - 1, character = col - 1 },
    context = { includeDeclaration = false },
  }

  vim.lsp.buf_request(bufnr, 'textDocument/references', params, function(err, result, _, _)
    assert(result, 'result is nil')
    assert(not err, 'err is not nil')
    for _, ref in ipairs(result) do
      local uri = ref.uri or ref.targetUri
      assert(uri, 'URI is nil')
      local range = ref.range or ref.targetSelectionRange
      assert(range, 'range is nil')
      assert(range.start, 'range.start is nil')
      local ref_line = range.start.line
      local func_ref_decl = M.find_enclosing_function(uri, ref_line)
      if func_ref_decl then
        local make_notify = require('mini.notify').make_notify {}
        make_notify(string.format('found: %s', func_ref_decl.func_name))
        if not string.find(func_ref_decl.filename, 'test') then
          M.add_to_quickfix(M.qflist, func_ref_decl.filename, func_ref_decl.location, func_ref_decl.text)
        end
      end
    end
    vim.cmd 'copen'
    vim.cmd 'wincmd p'
    vim.fn.setqflist(M.qflist, 'r')
  end)
  return M.qflist
end

local function load_func_ref_decls()
  local func_node = util_find_func.nearest_func_node()
  assert(func_node, 'No function found')
  local func_identifier
  for child in func_node:iter_children() do
    if child:type() == 'identifier' or child:type() == 'name' then
      func_identifier = child
    end
  end
  local start_row, start_col = func_identifier:range()
  M.lsp_ref_func_decl(vim.api.nvim_get_current_buf(), start_row + 1, start_col + 1)
end

function M.load_func_refs()
  if vim.fn.getqflist({ size = 0 }).size == 0 then
    load_func_ref_decls()
    M.last_func_decls = M.new_func_decls
  else
    M.new_func_decls = {}
    for _, item in ipairs(M.last_func_decls) do
      local filename = item.filename
      local bufnr = vim.fn.bufadd(filename)
      vim.fn.bufload(bufnr)
      M.lsp_ref_func_decl(bufnr, item.lnum, item.col)
    end
    M.last_func_decls = M.new_func_decls
  end
end

vim.api.nvim_create_user_command('ClearQuickFix', function()
  M.qflist = {}
  M.processed_funcs = {}
  vim.fn.setqflist {}
  vim.notify('Reset func ref decl quickfix list', vim.log.levels.INFO)
end, { desc = 'Reset func ref decl' })

return M
