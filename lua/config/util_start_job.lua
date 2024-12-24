local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

local function set_diagnostics_and_quickfix(output)
  local diagnostics = {}

  for _, line in ipairs(output) do
    local file, row, col, message = line:match '([^:]+):(%d+):(%d+): (.+)'
    if file and row and col and message then
      local bufnr = vim.fn.bufnr(file, false)
      table.insert(diagnostics, {
        bufnr = bufnr,
        lnum = tonumber(row) - 1, -- Line number (0-indexed)
        col = tonumber(col) - 1, -- Column number (0-indexed)
        message = message, -- The diagnostic message
        severity = vim.diagnostic.severity.ERROR, -- Set severity to ERROR
        source = 'golangci-lint',
        user_data = {},
      })
    end
  end

  for _, diagnostic in ipairs(diagnostics) do
    vim.diagnostic.set(vim.api.nvim_create_namespace 'golangci-lint', diagnostic.bufnr, diagnostics, {})
  end

  if #diagnostics > 0 then
    vim.diagnostic.setqflist {}
  end
end

Start_job = function(opts)
  local cmd = opts.cmd
  local silent = opts.silent
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
        set_diagnostics_and_quickfix(output)

        if #errors > 0 then
          print('Error:' .. table.concat(errors, '\n'))
        end

        return
      end

      if not silent then
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
