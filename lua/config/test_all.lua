local TerminalMultiplexer = require 'config.terminal_multiplexer'
local terminal_multiplexer = TerminalMultiplexer.new()

-- Function to run all tests and track their status
local function run_all_integration_tests()
  local source_bufnr = vim.api.nvim_get_current_buf()
  
  -- Clear existing test terminals and tracking
  M.reset_test()
  
  -- Create a new terminal for all tests
  local all_tests_name = "AllIntegrationTests"
  terminal_multiplexer:delete_terminal(all_tests_name)
  
  -- Prepare the test command
  local test_command
  if vim.fn.has('win32') == 1 then
    test_command = 'gitBash -c "go test integration_tests/*.go -v"'
  else
    test_command = 'go test integration_tests/*.go -v'
  end
  
  -- Create terminal
  local float_term_state = terminal_multiplexer:toggle_float_terminal(all_tests_name)
  assert(float_term_state, 'Failed to create floating terminal')
  
  -- Run the command
  vim.api.nvim_chan_send(float_term_state.chan, test_command .. '\n')
  
  -- Track test results
  local test_results = {}
  local current_test = nil
  
  vim.api.nvim_buf_attach(float_term_state.buf, false, {
    on_lines = function(_, buf, _, first_line, last_line)
      local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)
      local current_time = os.date('%H:%M:%S')
      
      for _, line in ipairs(lines) do
        -- Detect when a test starts
        local test_start = string.match(line, "=== RUN%s+(.+)")
        if test_start then
          current_test = test_start
          
          -- Create an entry for this test
          if not test_results[current_test] then
            test_results[current_test] = {
              name = current_test,
              status = "running",
              start_time = current_time
            }
            
            -- Find the test line
            local test_line = nil
            for test_name, line_num in pairs(Find_all_tests(source_bufnr)) do
              if test_name == current_test then
                test_line = line_num
                break
              end
            end
            
            -- Create test_info for the test tracker
            if test_line then
              local test_info = {
                test_name = current_test,
                test_line = test_line,
                test_bufnr = source_bufnr,
                test_command = test_command,
                status = "running"
              }
              
              table.insert(M.test_tracker, test_info)
              
              -- Add running indicator
              vim.api.nvim_buf_set_extmark(source_bufnr, ns, test_line - 1, 0, {
                virt_text = { { string.format('⏳ %s', current_time) } },
                virt_text_pos = 'eol',
              })
            end
          end
        end
        
        -- Detect test pass
        if current_test and string.match(line, "--- PASS: " .. current_test) then
          for _, test_info in ipairs(M.test_tracker) do
            if test_info.test_name == current_test then
              test_info.status = "passed"
              
              -- Update extmark to show pass
              vim.api.nvim_buf_set_extmark(source_bufnr, ns, test_info.test_line - 1, 0, {
                virt_text = { { string.format('✅ %s', current_time) } },
                virt_text_pos = 'eol',
              })
              
              make_notify(string.format('Test passed: %s', current_test))
              break
            end
          end
          
          test_results[current_test].status = "passed"
          test_results[current_test].end_time = current_time
          current_test = nil
        end
        
        -- Detect test fail
        if current_test and string.match(line, "--- FAIL: " .. current_test) then
          for _, test_info in ipairs(M.test_tracker) do
            if test_info.test_name == current_test then
              test_info.status = "failed"
              
              -- Update extmark to show fail
              vim.api.nvim_buf_set_extmark(source_bufnr, ns, test_info.test_line - 1, 0, {
                virt_text = { { string.format('❌ %s', current_time) } },
                virt_text_pos = 'eol',
              })
              
              make_notify(string.format('Test failed: %s', current_test))
              vim.notify(string.format('Test failed: %s', current_test), vim.log.levels.WARN, { title = 'Test Failure' })
              break
            end
          end
          
          test_results[current_test].status = "failed"
          test_results[current_test].end_time = current_time
          current_test = nil
        end
        
        -- Process error locations for failed tests
        local file, line_num = string.match(line, 'Error Trace:%s+([^:]+):(%d+)')
        if file and line_num then
          local error_line = tonumber(line_num)
          
          -- Try to find the buffer for this file
          local error_bufnr
          for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
            local buf_name = vim.api.nvim_buf_get_name(buf_id)
            if buf_name:match(file .. '$') then
              error_bufnr = buf_id
              break
            end
          end
          
          if error_bufnr then
            vim.fn.sign_define('GoTestError', { text = '✗', texthl = 'DiagnosticError' })
            vim.fn.sign_place(0, 'GoTestErrorGroup', 'GoTestError', error_bufnr, { lnum = error_line })
          end
        end
      end
      
      return false  -- Don't detach
    end,
  })
  
  return all_tests_name
end

-- Register command
vim.api.nvim_create_user_command('GoTestRunAll', run_all_integration_tests, {})

-- Register keymap
vim.keymap.set('n', '<leader>ta', run_all_integration_tests, { desc = 'Run all Go tests' })
