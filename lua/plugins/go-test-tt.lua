M = {
  'SearidangPa/go-test-tt.nvim',
  dependencies = {
    'echasnovski/mini.nvim',
  },
  config = function()
    vim.env.MODE, vim.env.UKS = 'staging', 'others'

    local integration_test_command_format
    if vim.fn.has 'win32' == 1 then
      integration_test_command_format = 'go test .\\integration_tests\\ -v -run %s\r'
    else
      integration_test_command_format = 'go test ./integration_tests/ -v -run %s'
    end

    local go_test_tt = require 'go-test-tt'
    go_test_tt.setup()
    M._terminal_test_set_up(integration_test_command_format)

    local terminal_test = require 'terminal_test.terminal_test'
    vim.keymap.set('n', '<localleader>st', function() terminal_test.terminals:search_terminal() end, { desc = '[S]earch Test [T]erminal' })

    ---@type Tracker
    local tracker = require 'terminal_test.tracker'
    vim.keymap.set('n', '<leader>tr', tracker.toggle_tracker_window, { desc = '[A]dd [T]est to tracker' })
    vim.keymap.set('n', '<leader>at', function() tracker.add_test_to_tracker 'go test ./... -v -run %s' end, { desc = '[A]dd [T]est to tracker' })
  end,
}

M._terminal_test_set_up = function(integration_test_command_format)
  local terminal_test = require 'terminal_test.terminal_test'
  vim.api.nvim_create_user_command('TerminalTest', function()
    local test_command_format = 'go test ./... -v -run %s'
    terminal_test.test_nearest_in_terminal(test_command_format)
  end, {})

  vim.api.nvim_create_user_command('TerminalTestBuf', function()
    local test_command_format = 'go test ./... -v -run %s'
    terminal_test.test_buf_in_terminals(test_command_format)
  end, {})

  vim.api.nvim_create_user_command('TerminalTestIntegration', function() terminal_test.test_nearest_in_terminal(integration_test_command_format) end, {})
  vim.api.nvim_create_user_command('TerminalTestIntegrationBuf', function() terminal_test.test_buf_in_terminals(integration_test_command_format) end, {})
  vim.api.nvim_create_user_command('GoTestSetModeDev', function()
    vim.env.MODE, vim.env.UKS = 'dev', 'others'
  end, {})
end

vim.api.nvim_create_user_command('ReloadTestT', function()
  local modules = {
    'display',
    'go-test-tt',
    'util_find_test',
    'util_status_icon',
    'terminal_test.terminal_multiplexer',
    'terminal_test.terminal_test',
    'terminal_test.tracker',
    'async_job.go_test',
    'async_job.util_quickfix',
  }

  for _, cmd in ipairs {
    'TerminalTest',
    'TerminalTestBuf',
    'TerminalTestIntegration',
    'TerminalTestIntegrationBuf',
    'TerminalTestSetModeStaging',
    'TerminalTestSetModeDev',
  } do
    if vim.fn.exists(':' .. cmd) > 0 then
      vim.cmd('delcommand ' .. cmd)
    end
  end

  for _, module in ipairs(modules) do
    package.loaded[module] = nil
  end

  -- Re-run your setup functions
  M._terminal_test_set_up()
  M._keybind_tracker()

  vim.notify('Terminal test plugin reloaded', vim.log.levels.INFO)
end, {})

return M
