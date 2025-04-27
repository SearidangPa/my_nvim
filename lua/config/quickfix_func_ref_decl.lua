local M = {}
local util_find_func = require 'config.util_find_func'
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

---@type QFList
M.qflist = {}

M.processed_funcs = {} -- Track function declarations we've already added

---@type QFList
M.new_func_decls = {} -- Track recent function declarations
M.last_func_decls = {} -- Track last function declarations

---@class QFList
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

function M.find_enclosing_function(uri, ref_line, ref_col)
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

  -- Include both function name and full signature in text
  local text = signature:gsub('^%s+', '') -- Remove leading whitespace

  local location = {
    line = func_range.start_row + 1, -- Convert from 0-indexed to 1-indexed
    col = func_range.start_col + 1,
  }
  return {
    filename = filename,
    location = location,
    text = text,
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
      local ref_col = range.start.character
      local func_ref_decl = M.find_enclosing_function(uri, ref_line, ref_col)
      if func_ref_decl then
        make_notify('found: ' .. func_ref_decl.text)
        M.add_to_quickfix(M.qflist, func_ref_decl.filename, func_ref_decl.location, func_ref_decl.text)
      end
    end
    vim.fn.setqflist(M.qflist)
  end)
  return M.qflist
end

local function load_func_ref_decls()
  local util_find_func = require 'config.util_find_func'
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

-- Combined function to handle both initial loading and additional layers
local function load_func_refs()
  -- Check if quickfix list is empty
  if vim.fn.getqflist({ size = 0 }).size == 0 then
    -- If empty, run the initial load (equivalent to <leader>ld)
    load_func_ref_decls()
    M.last_func_decls = M.new_func_decls
  else
    -- If not empty, load the next layer (original <leader>lr functionality)
    M.new_func_decls = {} -- Reset recent function declarations
    for _, item in ipairs(M.last_func_decls) do
      local filename = item.filename
      local bufnr = vim.fn.bufadd(filename)
      vim.fn.bufload(bufnr)
      M.lsp_ref_func_decl(bufnr, item.lnum, item.col)
    end
    M.last_func_decls = M.new_func_decls
    make_notify 'Additional function references loaded'
  end
end

-- Single keymap that combines both functionalities
vim.keymap.set('n', '<leader>lr', load_func_refs, { desc = '[L]oad function [R]eferences', noremap = true, silent = true })

vim.api.nvim_create_user_command('ResetFuncRefDecl', function()
  M.qflist = {}
  M.processed_funcs = {}
  vim.fn.setqflist {}
  make_notify 'Reset func ref decl quickfix list'
end, { desc = 'Reset func ref decl' })

return M
