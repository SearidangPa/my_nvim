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

  vim.api.nvim_create_user_command('TerminalTestIntegration', function()
    local test_command_format
    if vim.fn.has 'win32' == 1 then
      test_command_format = 'gitBash -c "go test integration_tests/*.go -v -run %s"\r'
    else
      test_command_format = 'go test integration_tests/*.go -v -run %s'
    end
    terminal_test.test_nearest_in_terminal(test_command_format)
  end, {})

  vim.api.nvim_create_user_command('TerminalTestIntegrationBuf', function()
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

local function keybind_tracker()
  local map = vim.keymap.set
  ---@type Tracker
  local tracker = require 'terminal_test.tracker'
  for _, idx in ipairs { 1, 2, 3, 4, 5, 6 } do
    map(
      'n',
      string.format('<leader>%d', idx),
      function() tracker.jump_to_tracked_test_by_index(idx) end,
      { desc = string.format('Jump to tracked test %d', idx) }
    )
  end

  for _, idx in ipairs { 1, 2, 3, 4, 5, 6 } do
    map(
      'n',
      string.format('<localleader>v%d', idx),
      function() tracker.toggle_tracked_terminal_by_index(idx) end,
      { desc = string.format('Toggle tracked test %d', idx) }
    )
  end

  vim.keymap.set('n', '<leader>tr', tracker.toggle_tracker_window, { desc = '[A]dd [T]est to tracker' })
  vim.keymap.set('n', '<leader>at', function() tracker.add_test_to_tracker 'go test ./... -v -run %s' end, { desc = '[A]dd [T]est to tracker' })
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
    keybind_tracker()
  end,
}
