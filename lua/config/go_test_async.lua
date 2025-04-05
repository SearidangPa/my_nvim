local M = {}
require 'config.util_find_func'
local make_notify = require('mini.notify').make_notify {}

M.clean_up_prev_job = function(job_id)
  if job_id ~= -1 then
    make_notify(string.format('stopping job: %d', job_id))
    vim.fn.jobstop(job_id)
    vim.diagnostic.reset()
  end
end

local attach_instace = {
  group = -1,
  ns = -1,
  job_id = -1,
}

local ignored_actions = {
  pause = true,
  cont = true,
  start = true,
  skip = true,
}

local make_key = function(entry)
  assert(entry.Package, 'Must have package name' .. vim.inspect(entry))
  if not entry.Test then
    return entry.Package
  end
  assert(entry.Test, 'Must have test name' .. vim.inspect(entry))
  return string.format('%s/%s', entry.Package, entry.Test)
end

local add_golang_test = function(test_state, entry)
  test_state.tests[make_key(entry)] = {
    name = entry.Test,
    output = {},
    fail_at_line = 0,
  }
end

local add_golang_output = function(test_state, entry)
  assert(test_state.tests, vim.inspect(test_state))
  local trimmed_output = vim.trim(entry.Output)
  local file, line = string.match(trimmed_output, '([%w_]+%.go):(%d+):')
  table.insert(test_state.tests[make_key(entry)].output, vim.trim(entry.Output))
  if file and line then
    test_state.tests[make_key(entry)].fail_at_line = tonumber(line)
  end
end

local mark_outcome = function(test_state, entry)
  local test = test_state.tests[make_key(entry)]
  if not test then
    return
  end
  test.success = entry.Action == 'pass'
end

M.run_test_all = function(command)
  local test_state = {
    tests = {},
    all_output = {},
  }

  local extmark_ids = {}
  M.clean_up_prev_job(attach_instace.job_id)

  attach_instace.job_id = vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data then
        return
      end

      for _, line in ipairs(data) do
        if line == '' then
          goto continue
        end
        local decoded = vim.json.decode(line)
        assert(decoded, 'Failed to decode: ' .. line)
        table.insert(test_state.all_output, decoded)

        if ignored_actions[decoded.Action] then
          goto continue
        end

        if decoded.Action == 'run' then
          add_golang_test(test_state, decoded)
          goto continue
        end

        if decoded.Action == 'output' then
          if decoded.Test then
            add_golang_output(test_state, decoded)
          end
          goto continue
        end

        local test = test_state.tests[make_key(decoded)]
        if not test then
          goto continue
        end

        if decoded.Action == 'pass' then
          mark_outcome(test_state, decoded)
          make_notify(string.format('%s passed', test.name))
        end

        if decoded.Action == 'fail' then
          mark_outcome(test_state, decoded)
          make_notify(string.format('%s failed', test.name))
        end

        ::continue::
      end
    end,

    on_exit = function() make_notify 'Job exited' end,
  })
end

vim.api.nvim_create_user_command('GoTestAll', function()
  local command = { 'go', 'test', './...', '-json', '-v' }
  M.run_test_all(command)
end, {})

return M
