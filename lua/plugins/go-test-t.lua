M = {
  'SearidangPa/go-test-t.nvim',
  dependencies = {
    'echasnovski/mini.nvim',
    'j-hui/fidget.nvim',
  },
  config = function()
    ---@type GoTestT
    local go_test_t = require 'go-test-t'
    local go_tester = go_test_t.new {}

    M._integration_test_set_up()

    -- ---@type TerminalTestTracker
    -- local tracker = require 'terminal_test.tracker'
    -- local map = vim.keymap.set
    -- map('n', '<leader>tr', tracker.toggle_tracker_window, { desc = '[A]dd [T]est to tracker' })
    -- map('n', '<leader>at', function() tracker.add_test_to_tracker 'go test ./... -v -run %s' end, { desc = '[A]dd [T]est to tracker' })
  end,
}

function M._default_set_up() end

function M._integration_test_set_up()
  local terminal_test = require 'terminal_test.terminal_test'

  local function get_integration_test_command_format()
    if vim.fn.has 'win32' == 1 then
      return 'go test .\\integration_tests\\ -v -run %s\r'
    else
      return 'go test ./integration_tests/ -v -run %s'
    end
  end

  local term_test = terminal_test.new { test_command_format = get_integration_test_command_format() }
  vim.api.nvim_create_user_command('TermIntegrationTest', function() term_test:test_nearest_in_terminal() end, {})
  vim.api.nvim_create_user_command('TermIntegrationTestBuf', function() term_test:test_buf_in_terminals() end, {})
  vim.api.nvim_create_user_command('TermIntegrationTestView', function() term_test:view_enclosing_test_terminal() end, {})
  vim.env.MODE, vim.env.UKS = 'staging', 'others'
  vim.api.nvim_create_user_command('SetModeDev', function()
    vim.env.MODE, vim.env.UKS = 'dev', 'others'
  end, {})
end

vim.api.nvim_create_user_command('ReloadTestT', function()
  local modules = {
    'display',
    'go-test-t',
    'util_find_test',
    'util_status_icon',
    'terminal_test.terminal_multiplexer',
    'terminal_test.terminal_test',
    'terminal_test.tracker',
    'util_quickfix',
  }

  for _, cmd in ipairs {
    'TerminalTest',
    'TerminalTestBuf',
  } do
    if vim.fn.exists(':' .. cmd) > 0 then
      vim.cmd('delcommand ' .. cmd)
    end
  end

  for _, module in ipairs(modules) do
    package.loaded[module] = nil
  end

  vim.notify('Terminal test plugin reloaded', vim.log.levels.INFO)
end, {})

return M
