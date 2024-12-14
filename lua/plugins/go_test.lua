local attach_to_buffer = function(bufnr, command)
  local state = {
    bufnr = bufnr,
    tests = {},
  }

  vim.api.nvim_buf_create_user_command(bufnr, 'GoTestLineDiag', function()
    local line = vim.fn.line '.' - 1
    for _, test in pairs(state.tests) do
      if test.Line == line then
        vim.cmd.new()
        vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), 0, -1, false, { test.Output })
      end
    end
  end, {})

  local make_key = function(entry)
    assert(entry.Package, 'Must have package name' .. vim.inspect(entry))
    assert(entry.Test, 'Must have test name' .. vim.inspect(entry))
    return string.format('%s/%s', entry.Package, entry.Test)
  end

  local add_golang_test = function(state, entry)
    state.tests[make_key(entry)] = {
      name = entry.Test,
      line = find_test_line(state.bufnr, entry.Test),
      output = {},
    }
  end

  local add_golang_output = function(state, entry)
    assert(state.tests, vim.inspect(state))
    table.insert(state.tests[make_key(entry)].output, vim.trim(entry.Output))
  end

  local mark_success = function(state, entry)
    state.tests[make_key(entry)].success = entry.Action == 'pass'
  end

  local ns = vim.api.nvim_create_namespace 'live_tests'
  local group = vim.api.nvim_create_augroup('teej-automagic', { clear = true })

  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*.go',
    callback = function()
      local append_data = function(_, data)
        if data then
          vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
        end
      end
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'output of main.go' })

      vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          if not data then
            return
          end
          append_data(_, data)

          for _, line in ipairs(data) do
            if line == '' then
              goto continue
            end

            local decoded = vim.json.decode(line)
            assert(decoded, 'Failed to decode: ' .. line)

            if decoded.Action == 'run' then
              add_golang_test(state, decoded)
            elseif decoded.Action == 'output' then
              if not decoded.Test then
                return
              end

              add_golang_output(state, decoded)
            elseif decoded.Action == 'pass' or decoded.Action == 'fail' then
              mark_success(state, decoded)
              local test = state.tests[make_key(decoded)]

              if test.success then
                local text = { '✅' }
                vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, 0, { virt_text = { text } })
              end
            elseif decoded.Action == 'pause' or decoded.Action == 'cont' then
              -- Do nothing
            else
              print('Failed to handle: ' .. vim.inspect(data))
            end

            ::continue::
          end
        end,

        on_stderr = append_data,
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
  local command = { 'go', 'test', '-json', '-v', '-run', GetEnclosingFunctionName() }
  attach_to_buffer(vim.api.nvim_get_current_buf(), command)
end, {})

vim.keymap.set('n', '<leader>cm', ':clear messages<CR>', { desc = '[C]lear [m]essages' })

return {}
