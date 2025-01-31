local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

Start_job = function(opts)
  local cmd = opts.cmd
  local invokeStr = table.concat(cmd, ' ')
  local output = {}
  local errors = {}
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
        local notif = string.format('%s failed with exit code %d', invokeStr, code)
        make_notify(notif, vim.log.levels.ERROR)
        return
      end
      local notif = string.format('%s completed successfully', invokeStr)
      make_notify(notif, vim.log.levels.INFO)

      if opts.on_success_cb then
        opts.on_success_cb()
      end
    end,
  })

  if job_id <= 0 then
    make_notify('Failed to start the Make command', vim.log.levels.ERROR)
  end
end
