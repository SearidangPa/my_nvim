M = {
  'SearidangPa/go-test-t.nvim',
  dependencies = {
    'echasnovski/mini.nvim',
  },
  config = function()
    vim.env.MODE, vim.env.UKS = 'staging', 'others'

    local go_test_tt = require 'go-test-t'
    go_test_tt.setup()

    local integration_test_command_format
    if vim.fn.has 'win32' == 1 then
      integration_test_command_format = 'go test .\\integration_tests\\ -v -run %s\r'
    else
      integration_test_command_format = 'go test ./integration_tests/ -v -run %s'
    end

    local terminal_test = require 'terminal_test.terminal_test'
    vim.api.nvim_create_user_command('TerminalIntegrationTest', function() terminal_test.test_nearest_in_terminal(integration_test_command_format) end, {})
    vim.api.nvim_create_user_command('TerminalIntegrationTestBuf', function() terminal_test.test_buf_in_terminals(integration_test_command_format) end, {})

    vim.api.nvim_create_user_command('GoTestSetModeDev', function()
      vim.env.MODE, vim.env.UKS = 'dev', 'others'
    end, {})

    ---@type TerminalTestTracker
    local tracker = require 'terminal_test.tracker'
    local map = vim.keymap.set
    map('n', '<leader>tr', tracker.toggle_tracker_window, { desc = '[A]dd [T]est to tracker' })
    map('n', '<leader>at', function() tracker.add_test_to_tracker 'go test ./... -v -run %s' end, { desc = '[A]dd [T]est to tracker' })
  end,
}

return M
