local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

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
        print('stdout' .. line)
        table.insert(output, line)
      end
    end,

    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        print('stderr' .. line)
        table.insert(errors, line)
      end
    end,

    on_exit = function(_, code)
      if code ~= 0 then
        make_notify(string.format('%s failed.\nOutput: %s\nError:%s', invokeStr, table.concat(output), table.concat(errors, '\n')), vim.log.levels.ERROR)
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
