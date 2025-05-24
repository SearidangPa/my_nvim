---@class QfItem
---@field filename string
---@field lnum number
---@field col number
---@field text string
---@field func_name? string

---@class FunctionInfo
---@field filename string
---@field location {line: number, col: number}
---@field text string
---@field func_name string

local M = {}

local state = {
  qflist = {},
  processed_functions = {},
  current_declarations = {},
  previous_declarations = {},
}

---@param qflist QfItem[]
---@param filename string
---@param location {line: number, col: number}
---@param text string
---@return boolean
local function add_to_quickfix(qflist, filename, location, text)
  local item = {
    filename = filename,
    lnum = location.line,
    col = location.col,
    text = text,
  }

  table.insert(qflist, item)
  table.insert(state.current_declarations, item)

  return true
end

---@param uri string
---@param ref_line number
local function find_enclosing_function(uri, ref_line)
  local filename = vim.uri_to_fname(uri)
  if not filename or filename:match '_test%.go$' then
    return nil
  end

  local bufnr = vim.fn.bufadd(filename)
  vim.fn.bufload(bufnr)

  local util_find_func = require 'custom.util_find_func'
  local func_node = util_find_func.enclosing_function_for_line(bufnr, ref_line)
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
  if state.processed_functions[func_key] then
    return nil
  end
  state.processed_functions[func_key] = true

  local lines = vim.api.nvim_buf_get_lines(bufnr, func_range.start_row, func_range.start_row + 1, false)
  local signature = lines[1]
  local text = signature:gsub('^%s+', '')

  local location = {
    line = func_range.start_row + 1,
    col = func_range.start_col + 1,
  }
  return {
    filename = filename,
    location = location,
    text = text,
    func_name = func_name,
  }
end

local function load_def_of_func_ref(bufnr, line, col)
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
      local enclosing_function_info = find_enclosing_function(uri, ref_line)
      if enclosing_function_info then
        local make_notify = require('mini.notify').make_notify {}
        make_notify(string.format('found: %s', enclosing_function_info.func_name))
        if not string.find(enclosing_function_info.filename, 'test') then
          add_to_quickfix(state.qflist, enclosing_function_info.filename, enclosing_function_info.location, enclosing_function_info.text)
        end
      end
    end
    vim.fn.setqflist(state.qflist, 'r')
    vim.schedule(function()
      vim.cmd 'copen'
      vim.cmd 'wincmd p'
    end)
  end)
  return state.qflist
end

function M.load_func_refs()
  if vim.fn.getqflist({ size = 0 }).size == 0 then
    local util_find_func = require 'custom.util_find_func'
    local func_node = util_find_func.nearest_func_node()
    assert(func_node, 'No function found')
    local func_identifier
    for child in func_node:iter_children() do
      if child:type() == 'identifier' or child:type() == 'name' then
        func_identifier = child
      end
    end
    local start_row, start_col = func_identifier:range()
    load_def_of_func_ref(vim.api.nvim_get_current_buf(), start_row + 1, start_col + 1)
    return
  end

  state.previous_declarations = vim.deepcopy(state.current_declarations)
  state.current_declarations = {}

  for _, item in ipairs(state.previous_declarations) do
    local filename = item.filename
    local bufnr = vim.fn.bufadd(filename)
    vim.fn.bufload(bufnr)
    load_def_of_func_ref(bufnr, item.lnum, item.col)
  end
end

local function clear_quickfix_state()
  state.qflist = {}
  state.processed_functions = {}
  state.current_declarations = {}
  state.previous_declarations = {}

  vim.fn.setqflist {}
  vim.notify('Quickfix cleared', vim.log.levels.INFO)
end

vim.api.nvim_create_user_command('ClearQuickFix', clear_quickfix_state, { desc = 'Clear quickfix list' })

return M
