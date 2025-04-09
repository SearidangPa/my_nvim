local terminal_test_set_up = function()
  local terminal_test = require 'terminal_test.terminal_test'
  vim.api.nvim_create_user_command('TerminalTest', function()
    local test_command_format = 'go test ./... -v -run %s'
    terminal_test.test_nearest_in_terminal(test_command_format)
  end, {})

  vim.api.nvim_create_user_command('TerminalTestBuf', function()
    local test_command_format = 'go test ./... -v -run %s'
    terminal_test.test_buf_in_terminals(test_command_format)
  end, {})

  vim.api.nvim_create_user_command('TestIntegration', function()
    local test_command_format
    if vim.fn.has 'win32' == 1 then
      test_command_format = 'gitBash -c "go test integration_tests/*.go -v -run %s"\r'
    else
      test_command_format = 'go test integration_tests/*.go -v -run %s'
    end
    terminal_test.test_nearest_in_terminal(test_command_format)
  end, {})

  vim.api.nvim_create_user_command('TestIntegrationBuf', function()
    local test_command_format
    if vim.fn.has 'win32' == 1 then
      test_command_format = 'gitBash -c "go test integration_tests/*.go -v -run %s"\r'
    else
      test_command_format = 'go test integration_tests/*.go -v -run %s'
    end
    terminal_test.test_buf_in_terminals(test_command_format)
  end, {})

  vim.api.nvim_create_user_command('TerminalTestSetModeStaging', function()
    vim.env.MODE, vim.env.UKS = 'staging', 'others'
  end, {})

  vim.api.nvim_create_user_command('TerminalTestSetModeDev', function()
    vim.env.MODE, vim.env.UKS = 'dev', 'others'
  end, {})
end

return {
  'SearidangPa/go-test-tt.nvim',
  dependencies = {
    'echasnovski/mini.nvim',
  },
  config = function()
    local go_test_tt = require 'go-test-tt'
    go_test_tt.setup()
    terminal_test_set_up()
  end,
}
