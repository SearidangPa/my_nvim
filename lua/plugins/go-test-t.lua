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
  end,
}

function M._integration_test_set_up()
  local function term_test_command_format()
    if vim.fn.has 'win32' == 1 then
      return 'go test .\\integration_tests\\ -v -run %s\r'
    else
      return 'go test ./integration_tests/ -v -run %s\r'
    end
  end

  local function test_command_format_json()
    if vim.fn.has 'win32' == 1 then
      return 'go test .\\integration_tests\\ -v --json %s\r'
    else
      return 'go test ./integration_tests/ -v --json %s\r'
    end
  end

  require('go-test-t').new {
    test_command_format_json = test_command_format_json(),
    term_test_command_format = term_test_command_format(),
  }

  vim.env.MODE, vim.env.UKS = 'staging', 'others'
  vim.api.nvim_create_user_command('SetModeDev', function()
    vim.env.MODE, vim.env.UKS = 'dev', 'others'
  end, {})
end

return M
