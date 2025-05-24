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

local function create_quickfix_item(function_info)
  return {
    filename = function_info.filename,
    lnum = function_info.location.line,
    col = function_info.location.col,
    text = function_info.text,
    func_name = function_info.func_name,
  }
end

local function add_function_to_quickfix(function_info)
  local item = create_quickfix_item(function_info)
  table.insert(state.qflist, item)
  table.insert(state.current_declarations, item)
end

local function is_test_file(filename) return filename and filename:match '_test%.go$' end

local function load_buffer_for_file(filename)
  local bufnr = vim.fn.bufadd(filename)
  vim.fn.bufload(bufnr)
  return bufnr
end

---@return TSNode|nil
local function find_function_identifier(func_node)
  for child in func_node:iter_children() do
    for _, func_type in ipairs { 'identifier', 'field_identifier', 'name' } do
      if child:type() == func_type then
        return child
      end
    end
  end
  return nil
end

local function get_function_key(filename, func_name, start_row) return filename .. ':' .. func_name .. ':' .. start_row end

local function is_function_already_processed(func_key)
  if state.processed_functions[func_key] then
    return true
  end
  state.processed_functions[func_key] = true
  return false
end

local function get_function_signature(bufnr, start_row)
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)
  local signature = lines[1] or ''
  return signature:gsub('^%s+', '')
end

--- Creates function information object from treesitter node
--- Extracts function name, location, and signature from the given function identifier
--- Returns nil if function was already processed to avoid duplicates
--- @param filename string
--- @param func_identifier TSNode
--- @param bufnr number
--- @return FunctionInfo|nil
local function create_function_info(filename, func_identifier, bufnr)
  local func_name = vim.treesitter.get_node_text(func_identifier, bufnr)
  local start_row, start_col = func_identifier:range()

  local func_key = get_function_key(filename, func_name, start_row)
  if is_function_already_processed(func_key) then
    return nil
  end

  local function_signature = get_function_signature(bufnr, start_row)

  return {
    filename = filename,
    location = {
      line = start_row + 1,
      col = start_col + 1,
    },
    text = function_signature,
    func_name = func_name,
  }
end

--- Gets function information for the function that encloses a given line
--- Loads the file buffer, finds the enclosing function using treesitter
--- Skips test files and returns nil if no function is found
--- @param uri string LSP URI of the file
--- @param ref_line number Line number to find enclosing function for
--- @return FunctionInfo|nil
local function get_enclosing_function_info(uri, ref_line)
  local filename = vim.uri_to_fname(uri)
  if not filename or is_test_file(filename) then
    return nil
  end

  local bufnr = load_buffer_for_file(filename)
  local util_find_func = require 'custom.util_find_func'
  local func_node = util_find_func.enclosing_function_for_line(bufnr, ref_line)

  if not func_node then
    vim.notify(string.format('No function found for %s:%d', filename, ref_line), vim.log.levels.WARN)
    return nil
  end

  local func_identifier = find_function_identifier(func_node)
  if not func_identifier then
    return nil
  end

  return create_function_info(filename, func_identifier, bufnr)
end

local function notify_function_found(func_name)
  local make_notify = require('mini.notify').make_notify {}
  make_notify(string.format('found: %s', func_name))
end

local function is_in_test_pkg(function_info) return function_info and not string.find(function_info.filename, 'test') end

--- Processes a single LSP reference to extract function information
--- Gets the enclosing function for the reference location
--- Adds valid functions to quickfix list if they're not test functions
--- @param ref table LSP reference object containing uri and range
local function process_fn_decl_of_ref(ref)
  local uri = ref.uri or ref.targetUri
  assert(uri, 'URI is nil')

  local range = ref.range or ref.targetSelectionRange
  assert(range, 'range is nil')
  assert(range.start, 'range.start is nil')

  local ref_line = range.start.line
  local function_info = get_enclosing_function_info(uri, ref_line)

  if function_info then
    notify_function_found(function_info.func_name)
    if is_in_test_pkg(function_info) then
      add_function_to_quickfix(function_info)
    end
  end
end

local function update_quickfix_window(create_new)
  if create_new then
    vim.fn.setqflist(state.qflist, ' ')
  else
    vim.fn.setqflist(state.qflist, 'r')
  end
  vim.schedule(function()
    vim.cmd 'copen'
    vim.cmd 'wincmd p'
  end)
end

local function create_lsp_params(bufnr, line, col)
  return {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = line - 1, character = col - 1 },
    context = { includeDeclaration = false },
  }
end

local function handle_references_response(err, result)
  assert(result, 'result is nil')
  assert(not err, 'err is not nil')

  for _, ref in ipairs(result) do
    process_fn_decl_of_ref(ref)
  end

  update_quickfix_window()
end

local function load_definition_of_reference(bufnr, line, col)
  assert(line, 'line is nil')
  assert(col, 'col is nil')

  local params = create_lsp_params(bufnr, line, col)
  vim.lsp.buf_request(bufnr, 'textDocument/references', params, handle_references_response)
  return state.qflist
end

local function get_current_function_position()
  local util_find_func = require 'custom.util_find_func'
  local func_node = util_find_func.nearest_func_node()
  assert(func_node, 'No function found')

  local func_identifier = find_function_identifier(func_node)
  assert(func_identifier, 'No function identifier found')
  local start_row, start_col = func_identifier:range()
  return start_row + 1, start_col + 1
end

local function load_initial_definitions()
  local current_buf = vim.api.nvim_get_current_buf()
  local line, col = get_current_function_position()
  load_definition_of_reference(current_buf, line, col)
end

local function prepare_for_next_iteration()
  state.previous_declarations = vim.deepcopy(state.current_declarations)
  state.current_declarations = {}
end

local function process_previous_declarations()
  for _, item in ipairs(state.previous_declarations) do
    local bufnr = load_buffer_for_file(item.filename)
    load_definition_of_reference(bufnr, item.lnum, item.col)
  end
end

local function is_quickfix_empty() return vim.fn.getqflist({ size = 0 }).size == 0 end

function M.load_definitions_to_refactor()
  if is_quickfix_empty() then
    load_initial_definitions()
    return
  end

  prepare_for_next_iteration()
  process_previous_declarations()
end

local function reset_state()
  state.qflist = {}
  state.processed_functions = {}
  state.current_declarations = {}
  state.previous_declarations = {}
end

local function clear_quickfix_state()
  reset_state()
  vim.fn.setqflist {}
  vim.notify('Quickfix cleared', vim.log.levels.INFO)
end

vim.api.nvim_create_user_command('ClearQuickFix', clear_quickfix_state, { desc = 'Clear quickfix list' })

-- === load function references for each func declarations in the quickfix list ===

local function create_reference_quickfix_item(ref)
  local filename = vim.uri_to_fname(ref.uri)
  local range = ref.range
  local start_line = range.start.line + 1
  local start_col = range.start.character + 1

  local bufnr = load_buffer_for_file(filename)
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)
  local line_text = lines[1] or ''

  return {
    filename = filename,
    lnum = start_line,
    col = start_col,
    text = line_text:gsub('^%s+', ''),
    func_name = nil,
  }
end

local function add_reference_to_quickfix(ref)
  if is_test_file(vim.uri_to_fname(ref.uri)) then
    return
  end

  local item = create_reference_quickfix_item(ref)
  table.insert(state.qflist, item)
end

function M.load_all_function_references()
  if vim.tbl_isempty(state.qflist) then
    vim.notify('No functions in quickfix list', vim.log.levels.WARN)
    return
  end

  local total_functions = #state.qflist
  local processed_count = 0
  local original_qflist = vim.deepcopy(state.qflist)
  state.qflist = {}

  local function process_next_function(index)
    if index > total_functions then
      local make_notify = require('mini.notify').make_notify {}
      make_notify(string.format('Loaded references for %d functions', processed_count))
      update_quickfix_window(true)
      return
    end

    local item = original_qflist[index]
    local bufnr = load_buffer_for_file(item.filename)

    local params = create_lsp_params(bufnr, item.lnum, item.col)

    vim.lsp.buf_request(bufnr, 'textDocument/references', params, function(err, result)
      if not err and result then
        for _, ref in ipairs(result) do
          add_reference_to_quickfix(ref)
        end
        processed_count = processed_count + 1
      end

      vim.schedule(function() process_next_function(index + 1) end)
    end)
  end

  process_next_function(1)
end

return M
