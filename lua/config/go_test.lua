require 'config.find_test_line'
local ns = vim.api.nvim_create_namespace 'live_tests'

local attach_to_buffer = function(bufnr, command)
  local state = {
    bufnr = bufnr,
    tests = {},
  }

  local testsCurrBuf = Find_all_tests(bufnr)

  vim.api.nvim_buf_create_user_command(bufnr, 'GoTestDiag', function()
    vim.cmd.new()
    for _, test in pairs(state.tests) do
      if test.success == false then
        local currentBuf = vim.api.nvim_get_current_buf()
        local num_lines = vim.api.nvim_buf_line_count(currentBuf)
        vim.api.nvim_buf_set_lines(currentBuf, num_lines, num_lines, false, test.output)
      end
    end
  end, {})

  vim.api.nvim_buf_create_user_command(bufnr, 'GoTestLineDiag', function()
    local testLine, _ = GetEnclosingFunctionName()
    testLine = testLine - 1
    for _, test in pairs(state.tests) do
      if test.line == testLine then
        vim.cmd.new()
        vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), 0, -1, false, test.output)
      end
    end
  end, {})

  local make_key = function(entry)
    assert(entry.Package, 'Must have package name' .. vim.inspect(entry))
    assert(entry.Test, 'Must have test name' .. vim.inspect(entry))
    return string.format('%s/%s', entry.Package, entry.Test)
  end

  local add_golang_test = function(entry)
    state.tests[make_key(entry)] = {
      name = entry.Test,
      line = testsCurrBuf[entry.Test] - 1,
      output = {},
    }
  end

  local add_golang_output = function(entry)
    assert(state.tests, vim.inspect(state))
    table.insert(state.tests[make_key(entry)].output, vim.trim(entry.Output))
  end

  local mark_success = function(entry)
    state.tests[make_key(entry)].success = entry.Action == 'pass'
  end

  local virtualText = { '✅' }
  local group = vim.api.nvim_create_augroup('teej-automagic', { clear = true })

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

            if decoded.Action == 'run' then
              add_golang_test(decoded)
            elseif decoded.Action == 'output' then
              if not decoded.Test then
                return
              end

              add_golang_output(decoded)
            elseif decoded.Action == 'pass' or decoded.Action == 'fail' then
              mark_success(decoded)
              local test = state.tests[make_key(decoded)]

              if test.success then
                -- from start to end of the test line
                local existing_extmarks = vim.api.nvim_buf_get_extmarks(state.bufnr, ns, { test.line, 0 }, { test.line, -1 }, {})
                if #existing_extmarks < 1 then
                  vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, 0, {
                    virt_text = { virtualText },
                  })
                end
              end
            elseif decoded.Action == 'pause' or decoded.Action == 'cont' or decoded.Action == 'start' then
              -- Do nothing
            else
              print('Failed to handle: ' .. line)
            end

            ::continue::
          end
        end,

        on_exit = function()
          local failed = {}
          for _, test in pairs(state.tests) do
            if test.line then
              if not test.success then
                table.insert(failed, {
                  bufnr = bufnr,
                  lnum = test.line,
                  col = 0,
                  severity = vim.diagnostic.severity.ERROR,
                  source = 'go-test',
                  message = 'Test Failed',
                  user_data = {},
                })
              end
            end
          end

          vim.diagnostic.set(ns, bufnr, failed, {})
        end,
      })
    end,
  })
end

vim.api.nvim_create_user_command('GoTestOnSave', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local testsInCurrBuf = Find_all_tests(bufnr)
  local concatTestName = ''
  for testName, _ in pairs(testsInCurrBuf) do
    concatTestName = concatTestName .. testName .. '|'
  end
  concatTestName = concatTestName:sub(1, -2) -- remove the last |

  local command = { 'go', 'test', '-json', '-v', '-run', string.format('%s', concatTestName) }
  if vim.fn.has 'win32' == 1 then
    table.insert(command, 1, 'C:\\Program Files\\Git\\bin\\bash.exe')
    table.insert(command, 2, '-c')
  end

  print(string.format('Running: %s', table.concat(command, ' ')))
  attach_to_buffer(vim.api.nvim_get_current_buf(), command)
end, {})

vim.keymap.set('n', '<leader>xa', ':GoTestOnSave<CR>', { desc = 'Auto-run tests on save' })
vim.keymap.set('n', '<leader>xd', ':GoTestLineDiag<CR>', { desc = 'Show test output for failed test' })

-- Clear namespace and reset diagnostic
vim.keymap.set('n', '<leader>cn', function()
  vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), ns, 0, -1)
  vim.diagnostic.reset()
end, { desc = '[C]lear [N]amespace and reset diagnostic' })

-- unattach the autocommand
vim.keymap.set('n', '<leader>cg', function()
  vim.api.nvim_del_augroup_by_name 'teej-automagic'
  vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), ns, 0, -1)
  vim.diagnostic.reset()
end, { desc = '[C]lear [G]roup, clear ext_mark and reset diagnostic' })

return {}
