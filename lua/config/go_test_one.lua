require 'config.find_test_line'
require 'config.floating_window'

local attach_to_buffer = function(bufnr, command)
  local state = {
    bufnr = bufnr,
    tests = {},
  }

  vim.api.nvim_buf_create_user_command(bufnr, 'GoTestOutput', function()
    Go_test_output(state)
  end, {})

  local group = vim.api.nvim_create_augroup('teej-automagic', { clear = true })
  local extmark_id = -1
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

            if Ignored_actions[decoded.Action] then
              goto continue
            end

            if decoded.Action == 'run' then
              Add_golang_test(bufnr, state, decoded)
              goto continue
            end

            if decoded.Action == 'output' then
              if decoded.Test then
                Add_golang_output(decoded)
              end
              goto continue
            end

            if decoded.Action == 'pass' or decoded.Action == 'fail' then
              Mark_success(decoded)
              local test = state.tests[Make_key(decoded)]
              if not test then
                goto continue
              end
              if not test.success then
                goto continue
              end

              if extmark_id ~= -1 then
                vim.api.nvim_buf_del_extmark(bufnr, ns_one, extmark_id)
              end

              local current_time = os.date '%H:%M:%S'
              extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_one, test.line, -1, {
                virt_text = {
                  { string.format('%s %s', '✅', current_time) },
                },
                virt_lines_leftcol = true,
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

          vim.diagnostic.set(ns_one, bufnr, failed, {})
        end,
      })
    end,
  })
end

-- unattach the autocommand
vim.api.nvim_create_user_command('StopGoTestOnSave', function()
  vim.api.nvim_del_augroup_by_name 'teej-automagic'
  vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), ns_one, 0, -1)
  vim.diagnostic.reset()
end, {})

return {}
