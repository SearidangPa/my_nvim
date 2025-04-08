local M = {}
local make_notify = require('mini.notify').make_notify {}

-- Common utility functions
local function ensure_valid_buffer(file)
  local file_path = file:gsub('\\', '/')
  local file_bufnr = vim.fn.bufnr(file_path)
  if not vim.api.nvim_buf_is_valid(file_bufnr) then
    file_bufnr = vim.fn.bufadd(file_path)
    vim.fn.bufload(file_bufnr)
  end
  return file_bufnr
end

local function create_diagnostic(file_bufnr, row, col, message)
  return {
    bufnr = file_bufnr,
    col = tonumber(col) - 1, -- Column number (0-indexed)
    message = message,
    severity = vim.diagnostic.severity.ERROR,
    source = 'golangci-lint',
    user_data = {},
  }
end

local function add_diagnostic(diagnostics_map, file_bufnr, diagnostic)
  if not diagnostics_map.diagnostics_list_per_bufnr[file_bufnr] then
    diagnostics_map.diagnostics_list_per_bufnr[file_bufnr] = {}
  end
  table.insert(diagnostics_map.diagnostics_list_per_bufnr[file_bufnr], diagnostic)
end

local function parse_windows_diagnostics(output)
  local diagnostics_map = {
    diagnostics_list_per_bufnr = {},
  }

  local output_str = type(output) == 'table' and table.concat(output, '\n') or output
  for log_line in output_str:gmatch '([^\r\n]+)' do
    local error_msg = log_line:match 'level=error msg="[^"]*typechecking error: :(.-)"'
    if error_msg then
      error_msg = error_msg:gsub('\\n', '\n')
      for diag_line in error_msg:gmatch '([^\r\n]+)' do
        if not diag_line:match '^# ' then
          local file, row, col, message = diag_line:match '([^:]+):(%d+):(%d+): (.+)'
          if file and row and col and message then
            local file_bufnr = ensure_valid_buffer(file)
            local diagnostic = create_diagnostic(file_bufnr, row, col, message)
            add_diagnostic(diagnostics_map, file_bufnr, diagnostic)
          end
        end
      end
    end
  end

  return diagnostics_map
end

local function parse_unix_diagnostics(output)
  local diagnostics_map = {
    diagnostics_list_per_bufnr = {},
  }

  for _, line in ipairs(output) do
    local file, row, col, message = line:match '([^:]+):(%d+):(%d+): (.+)'
    if file and row and col and message then
      local file_bufnr = ensure_valid_buffer(file)
      local diagnostic = create_diagnostic(file_bufnr, row, col, message)
      add_diagnostic(diagnostics_map, file_bufnr, diagnostic)
    end
  end

  return diagnostics_map
end

local function create_quickfix_list(diagnostics_map)
  local quickfix_list = {}

  for bufnr, diagnostics in pairs(diagnostics_map.diagnostics_list_per_bufnr) do
    for _, diag in ipairs(diagnostics) do
      table.insert(quickfix_list, {
        bufnr = bufnr,
        col = diag.col + 1,
        text = diag.message,
        type = 'E', -- Error type for quickfix
      })
    end
  end

  return quickfix_list
end

local function set_diagnostics_and_quickfix(output, ns)
  vim.diagnostic.reset(ns)

  local diagnostics_map
  if vim.fn.has 'win32' == 1 then
    diagnostics_map = parse_windows_diagnostics(output)
  else
    diagnostics_map = parse_unix_diagnostics(output)
  end

  for bufnr, diagnostics in pairs(diagnostics_map.diagnostics_list_per_bufnr) do
    vim.diagnostic.set(ns, bufnr, diagnostics, {})
  end

  local quickfix_list = create_quickfix_list(diagnostics_map)
  if #quickfix_list > 0 then
    vim.fn.setqflist(quickfix_list, 'r')
    vim.cmd 'copen'
  end
end

---@class opts
---@field cmd string|table
---@field silent boolean
---@field ns number
---@field on_success_cb function

---@param opts opts
M.start_job = function(opts)
  local cmd = opts.cmd
  local silent = opts.silent
  local ns = opts.ns or vim.api.nvim_create_namespace 'start-job'
  local output = {}
  local errors = {}

  local invokeStr
  if type(cmd) == 'table' then
    invokeStr = table.concat(cmd, ' ')
  else
    invokeStr = cmd
  end

  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        table.insert(output, line)
      end
    end,

    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        table.insert(errors, line)
      end
    end,

    on_exit = function(_, code)
      if code ~= 0 then
        make_notify(string.format('%s failed', invokeStr), vim.log.levels.ERROR)
        vim.list_extend(output, errors)

        set_diagnostics_and_quickfix(output, ns)

        if #errors > 0 then
          print('Error:' .. table.concat(errors, '\n'))
        end

        return
      end

      if not silent then
        vim.diagnostic.reset(ns)
        vim.fn.setqflist({}, 'r')
        local notif = string.format('%s completed successfully', invokeStr)
        make_notify(notif, vim.log.levels.INFO)
      end

      if opts.on_success_cb then
        opts.on_success_cb()
      end
    end,
  })

  if job_id <= 0 then
    make_notify('Failed to start the Make command', vim.log.levels.ERROR)
  end

  return job_id, output, errors
end

function Contains(tbl, value)
  for _, v in ipairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

return M
