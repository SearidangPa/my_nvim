require 'config.find_test_line'
require 'config.floating_window'
require 'config.go_test_one'

local function Go_tests_Output(state, filter_for_sucess)
  local buf = Create_floating_window({}, 0, -1)
  for _, test in pairs(state.tests) do
    if test.success == filter_for_sucess then
      local num_lines = vim.api.nvim_buf_line_count(buf)
      vim.api.nvim_buf_set_lines(buf, num_lines, -1, false, test.output)
    end
  end
end

local ns = vim.api.nvim_create_namespace 'live_tests_all'
local attach_to_buffer = function(bufnr, command)
  local state = {
    bufnr = bufnr,
    tests = {},
  }

  vim.api.nvim_buf_create_user_command(bufnr, 'GoTestsAllFailedOutput', function()
    Go_tests_Output(state, false)
  end, {})

  vim.api.nvim_buf_create_user_command(bufnr, 'GoTestsSuccessOutput', function()
    Go_tests_Output(state, true)
  end, {})

  vim.api.nvim_buf_create_user_command(bufnr, 'GoTestOutput', function()
    Go_test_Output(state)
  end, {})

  local make_key = function(entry)
    assert(entry.Package, 'Must have package name' .. vim.inspect(entry))
    if not entry.Test then
      return entry.Package
    end
    assert(entry.Test, 'Must have test name' .. vim.inspect(entry))
    return string.format('%s/%s', entry.Package, entry.Test)
  end

  local add_golang_test = function(entry)
    local testLine = Find_test_line_by_name(bufnr, entry.Test)
    if not testLine then
      testLine = 0
    end

    state.tests[make_key(entry)] = {
      name = entry.Test,
      line = testLine - 1,
      output = {},
    }
  end

  local add_golang_output = function(entry)
    assert(state.tests, vim.inspect(state))
    local state_entry = state.tests[make_key(entry)]
    if not state_entry then
      for k, v in pairs(state.tests) do
        table.insert(v.output, vim.trim(entry.Output))
        print(k, v)
      end
      return
    end
    table.insert(state.tests[make_key(entry)].output, vim.trim(entry.Output))
  end

  local mark_success = function(entry)
    local test = state.tests[make_key(entry)]
    if not test then
      return
    end
    test.success = entry.Action == 'pass'
  end

  local group = vim.api.nvim_create_augroup('all_tests_automagic', { clear = true })
  local ignored_actions = {
    pause = true,
    cont = true,
    start = true,
    skip = true,
  }

  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*.go',
    callback = function()
      vim.fn.jobstart(command, {
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
            print(vim.inspect(decoded))

            if ignored_actions[decoded.Action] then
              goto continue
            end

            if decoded.Action == 'run' then
              add_golang_test(decoded)
              goto continue
            end

            if decoded.Action == 'output' then
              if decoded.Test then
                add_golang_output(decoded)
              end
              goto continue
            end

            if decoded.Action == 'pass' or decoded.Action == 'fail' then
              mark_success(decoded)
              local test = state.tests[make_key(decoded)]
              if not test then
                goto continue
              end
              if not test.success then
                goto continue
              end

              local current_time = os.date '%H:%M:%S'
              vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, -1, {
                virt_text = {
                  { string.format('%s %s', '✅', current_time) },
                },
              })
              goto continue
            end

            print('Failed to handle: ' .. line)
            ::continue::
          end
        end,

        on_exit = function()
          print 'Tests finished'
          local failed = {}
          for _, test in pairs(state.tests) do
            if not test.line or test.success then
              goto continue
            end

            table.insert(failed, {
              bufnr = bufnr,
              lnum = test.line,
              col = 0,
              severity = vim.diagnostic.severity.ERROR,
              source = 'go-test',
              message = 'Test Failed',
              user_data = {},
            })

            ::continue::
          end

          vim.diagnostic.set(ns, bufnr, failed, {})
        end,
      })
    end,
  })
end

vim.api.nvim_create_user_command('GoTestAllOnSave', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local testsInCurrBuf = Find_all_tests(bufnr)
  local concatTestName = ''
  for testName, _ in pairs(testsInCurrBuf) do
    concatTestName = concatTestName .. testName .. '|'
  end
  concatTestName = concatTestName:sub(1, -2) -- remove the last |
  local command = { 'go', 'test', './...', '-json', '-v', '-run', string.format('%s', concatTestName) }
  attach_to_buffer(bufnr, command)
end, {})

-- unattach the autocommand
vim.api.nvim_create_user_command('StopGoTestAllOnSave', function()
  vim.api.nvim_del_augroup_by_name 'all_tests_automagic'
  vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), ns, 0, -1)
  vim.diagnostic.reset()
end, {})

return {}
