M = {
  'SearidangPa/go-test-t.nvim',
  dependencies = {
    'echasnovski/mini.nvim',
    'j-hui/fidget.nvim',
  },
  config = function()
    local go_test_tt = require 'go-test-t'
    go_test_tt.setup()
    M._integration_test_set_up()

    ---@type TerminalTestTracker
    local tracker = require 'terminal_test.tracker'
    local map = vim.keymap.set
    map('n', '<leader>tr', tracker.toggle_tracker_window, { desc = '[A]dd [T]est to tracker' })
    map('n', '<leader>at', function() tracker.add_test_to_tracker 'go test ./... -v -run %s' end, { desc = '[A]dd [T]est to tracker' })
  end,
}

function M._integration_test_set_up()
  local terminal_test = require 'terminal_test.terminal_test'

  local terminal_test_instance = terminal_test.new {
    test_command_format = M._integration_test_command_format(),
  }
  local map = vim.keymap.set
  map('n', '<leader>G', function() terminal_test_instance:test_nearest_in_terminal() end, { desc = '[G]o test in terminal' })
  map('n', '<leader>T', function() terminal_test_instance:view_enclosing_test_terminal() end, { desc = 'view test [T]erminal' })

  vim.env.MODE, vim.env.UKS = 'staging', 'others'
  vim.api.nvim_create_user_command('GoTestSetModeDev', function()
    vim.env.MODE, vim.env.UKS = 'dev', 'others'
  end, {})
end

function M._get_integration_test_command_format()
  if vim.fn.has 'win32' == 1 then
    return 'go test .\\integration_tests\\ -v -run %s\r'
  else
    return 'go test ./integration_tests/ -v -run %s'
  end
end

return M
