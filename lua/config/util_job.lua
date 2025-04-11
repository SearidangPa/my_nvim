local M = {}

local make_notify = require('mini.notify').make_notify {}

local function get_diagnostic_map_windows(output)
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
            file = file:gsub('\\', '/')

            local file_bufnr = vim.fn.bufnr(file)
            if not vim.api.nvim_buf_is_valid(file_bufnr) then
              file_bufnr = vim.fn.bufadd(file)
              vim.fn.bufload(file_bufnr)
            end

            local diagnostic = {
              bufnr = file_bufnr,
              lnum = tonumber(row) - 1,
              col = tonumber(col) - 1,
              message = message,
              severity = vim.diagnostic.severity.ERROR,
              source = 'golangci-lint',
              user_data = {},
            }

            if not diagnostics_map.diagnostics_list_per_bufnr[file_bufnr] then
              diagnostics_map.diagnostics_list_per_bufnr[file_bufnr] = {}
            end
            table.insert(diagnostics_map.diagnostics_list_per_bufnr[file_bufnr], diagnostic)
          end
        end
      end
    end
  end

  return diagnostics_map
end

local function get_diagnostic_map_unix(output)
  local diagnostics_map = {
    diagnostics_list_per_bufnr = {},
  }

  for _, line in ipairs(output) do
    local file, row, col, message = line:match '([^:]+):(%d+):(%d+): (.+)'
    local file_bufnr = -1

    if file and row and col and message then
      file_bufnr = vim.fn.bufnr(file)

      if not vim.api.nvim_buf_is_valid(file_bufnr) then
        file_bufnr = vim.fn.bufadd(file)
        vim.fn.bufload(file_bufnr)
      end

      local diagnostic = {
        bufnr = file_bufnr,
        lnum = tonumber(row) - 1, -- Line number (0-indexed)
        col = tonumber(col) - 1, -- Column number (0-indexed)
        message = message, -- The diagnostic message
        severity = vim.diagnostic.severity.ERROR, -- Set severity to ERROR
        source = 'golangci-lint',
        user_data = {},
      }

      if not diagnostics_map.diagnostics_list_per_bufnr[file_bufnr] then
        diagnostics_map.diagnostics_list_per_bufnr[file_bufnr] = {}
      end
      table.insert(diagnostics_map.diagnostics_list_per_bufnr[file_bufnr], diagnostic)
    end
  end
  return diagnostics_map
end

local function set_diagnostics_and_quickfix(output, ns)
  vim.diagnostic.reset(ns)

  local diagnostics_map
  if vim.fn.has 'win32' == 1 then
    diagnostics_map = get_diagnostic_map_windows(output)
  else
    diagnostics_map = get_diagnostic_map_unix(output)
  end

  for bufnr, diagnostics in pairs(diagnostics_map.diagnostics_list_per_bufnr) do
    vim.diagnostic.set(ns, bufnr, diagnostics, {})
  end

  local quickfix_list = {}
  for bufnr, diagnostics in pairs(diagnostics_map.diagnostics_list_per_bufnr) do
    for _, diag in ipairs(diagnostics) do
      table.insert(quickfix_list, {
        bufnr = bufnr,
        lnum = diag.lnum + 1, -- Convert back to 1-indexed for quickfix
        col = diag.col + 1,
        text = diag.message,
        type = 'E', -- Error type for quickfix
      })
    end
  end

  if #quickfix_list > 0 then
    vim.fn.setqflist(quickfix_list, 'r')
    vim.cmd 'copen'
  end
end

---@class opts
---@field cmd string|table
---@field ns number
---@field on_success_cb function

---@param opts opts
function M.start_job(opts)
  local fidget = require 'fidget'
  local cmd = opts.cmd
  local ns = opts.ns or vim.api.nvim_create_namespace 'start-job'
  local output = {}
  local errors = {}

  local invokeStr

  if type(cmd) == 'table' then
    invokeStr = table.concat(cmd, ' ')
  else
    invokeStr = cmd
  end

  local fidget_handle = fidget.progress.handle.create {
    title = invokeStr,
    lsp_client = {
      name = 'build',
    },
  }

  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    stderr_buffered = false,

    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        line = vim.trim(line)
        if line ~= '' then
          table.insert(output, line)
          fidget_handle:report { message = string.format('%s: %s', invokeStr, line) }
        end
      end
    end,

    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if vim.trim(line) ~= '' then
          table.insert(errors, line)
          fidget_handle:report { message = string.format('%s: %s', invokeStr, line) }
        end
      end
    end,

    on_exit = function(_, code)
      if code ~= 0 then
        vim.list_extend(output, errors)
        set_diagnostics_and_quickfix(output, ns)
        if #errors > 0 then
          print('Error:' .. table.concat(errors, '\n'))
        end
        fidget.notify(string.format('%s failed', invokeStr), vim.log.levels.ERROR)
        fidget_handle:finish()
      else
        vim.diagnostic.reset(ns)
        vim.fn.setqflist({}, 'r')
        fidget_handle:finish()
      end

      if opts.on_success_cb then
        opts.on_success_cb()
      end
    end,
  })

  if job_id <= 0 then
    make_notify('Failed to start the Make command', vim.log.levels.ERROR)
    fidget_handle:cancel()
  end
end

return M
