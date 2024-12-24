local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

local function set_linter_quickfix(output)
  local diagnostics = {}
  for _, line in ipairs(output) do
    local file, row, col, message = line:match '([^:]+):(%d+):(%d+): (.+)'
    if file and row and col and message then
      table.insert(diagnostics, {
        filename = file,
        lnum = tonumber(row),
        col = tonumber(col),
        text = message,
        type = 'E',
      })
    end
  end

  if #diagnostics > 0 then
    vim.fn.setqflist({}, 'r', { title = 'Linter Diagnostics', items = diagnostics })
    vim.cmd 'copen' -- Open the quickfix window
    return
  end

  print 'No diagnostics found'
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
        set_linter_quickfix(output)

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
