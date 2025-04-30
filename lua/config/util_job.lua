local util_job = {}

local function get_diagnostic_map(output)
  local diagnostics_map = {
    diagnostics_list_per_bufnr = {},
  }

  local output_str = type(output) == 'table' and table.concat(output, '\n') or output

  for line in output_str:gmatch '([^\r\n]+)' do
    local file, row, col, message = line:match '([^:]+):(%d+):(%d+): (.+)'

    if file and row and col and message then
      if vim.fn.has 'win32' == 1 then
        file = file:gsub('\\', '/')
      end

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

  return diagnostics_map
end

local function set_diagnostics_and_quickfix(cmd, output, ns)
  local diagnostics_map
  if cmd:match 'lint' then
    if vim.fn.has 'win32' == 1 then
      print 'Open trouble diagnostics to fix linter errors with: <leader><leader>'
      return
    end
  end
  vim.diagnostic.reset(ns)
  diagnostics_map = get_diagnostic_map(output)

  assert(diagnostics_map, 'diagnostics_map is required')
  for bufnr, diagnostics in pairs(diagnostics_map.diagnostics_list_per_bufnr) do
    vim.diagnostic.set(ns, bufnr, diagnostics, {})
  end

  local quickfix_list = {}
  for bufnr, diagnostics in pairs(diagnostics_map.diagnostics_list_per_bufnr) do
    for _, diag in ipairs(diagnostics) do
      table.insert(quickfix_list, {
        bufnr = bufnr,
        lnum = diag.lnum + 1,
        col = diag.col + 1,
        text = diag.message,
        type = 'E',
      })
    end
  end

  if #quickfix_list > 0 then
    vim.fn.setqflist(quickfix_list, 'r')
    vim.cmd 'copen'
  end
end

---@class Job.opts
---@field cmd string|table
---@field ns number
---@field fidget_handle? ProgressHandle
---@field on_success_cb? fun()

---@param opts Job.opts
function util_job.start_job(opts)
  assert(opts.cmd, 'cmd is required')
  assert(opts.ns, 'ns is required')
  local make_notify = require('mini.notify').make_notify {}
  local cmd = opts.cmd
  local ns = opts.ns
  local output = {}
  local errors = {}

  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    stderr_buffered = false,

    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        line = vim.trim(line)
        if line ~= '' then
          table.insert(output, line)
        end
        if opts.fidget_handle then
          opts.fidget_handle:report { string.format('output: %d line', #output) }
        end
      end
    end,

    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if vim.trim(line) ~= '' then
          table.insert(errors, line)
        end
      end
    end,

    on_exit = function(_, code)
      if opts.fidget_handle then
        opts.fidget_handle:finish()
      end
      if code ~= 0 then
        vim.list_extend(output, errors)
        local qflist = vim.fn.getqflist()
        if #qflist == 0 then
          set_diagnostics_and_quickfix(cmd, output, ns)
        else
          vim.notify('Lint failed. Stuff in the quickfix so will not override quickfix', vim.log.levels.ERROR)
        end
        make_notify(string.format('%s failed', cmd), vim.log.levels.ERROR)
      else
        vim.diagnostic.reset(ns)
        vim.fn.setqflist({}, 'r')
        if opts.on_success_cb then
          opts.on_success_cb()
        end
      end
    end,
  })

  if job_id <= 0 then
    make_notify('Failed to start the Make command', vim.log.levels.ERROR)
  end
end

return util_job
