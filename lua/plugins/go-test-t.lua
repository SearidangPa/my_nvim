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
    M._setup_user_commands(go_tester, 'GoTest')
  end,
}

---@param go_tester GoTestT
---@param user_command_prefix string
function M._setup_user_commands(go_tester, user_command_prefix)
  local term_tester = go_tester.term_tester
  vim.api.nvim_create_user_command(user_command_prefix .. 'All', function() go_tester:run_test_all() end, {})
  vim.api.nvim_create_user_command(user_command_prefix .. 'ToggleDisplay', function() go_tester:toggle_display() end, {})
  vim.api.nvim_create_user_command(user_command_prefix .. 'LoadQuackTestQuickfix', function() go_tester:load_quack_tests() end, {})

  vim.api.nvim_create_user_command(user_command_prefix .. 'Term', function() term_tester:test_nearest_in_terminal() end, {})
  vim.api.nvim_create_user_command(user_command_prefix .. 'TermBuf', function() term_tester:test_buf_in_terminals() end, {})
  vim.api.nvim_create_user_command(user_command_prefix .. 'TermView', function() term_tester:view_enclosing_test_terminal() end, {})
  vim.api.nvim_create_user_command(user_command_prefix .. 'TermSearch', function() term_tester.terminals:search_terminal() end, {})
  vim.api.nvim_create_user_command(user_command_prefix .. 'TermViewLast', function() term_tester:view_last_test_terminal() end, {})
  vim.api.nvim_create_user_command(user_command_prefix .. 'TermToggleDisplay', function() term_tester.term_test_displayer:toggle_display() end, {})

  -- ---@type TerminalTestTracker
  -- local tracker = require 'terminal_test.tracker'
  -- local map = vim.keymap.set
  -- map('n', '<leader>tr', tracker.toggle_tracker_window, { desc = '[A]dd [T]est to tracker' })
  -- map('n', '<leader>at', function() tracker.add_test_to_tracker 'go test ./... -v -run %s' end, { desc = '[A]dd [T]est to tracker' })
end

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

return M
