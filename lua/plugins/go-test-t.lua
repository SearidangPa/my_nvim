return {
  'SearidangPa/go-test-t.nvim',
  dependencies = {
    'echasnovski/mini.nvim',
    'j-hui/fidget.nvim',
  },
  config = function()
    vim.env.UKS = 'others'
    vim.env.MODE = 'staging'

    local function term_test_command_format()
      if vim.fn.has 'win32' == 1 then
        return 'go test .\\integration_tests\\ -v -run %s\r'
      else
        return 'go test integration_tests/*.go -v -run %s\r'
      end
    end

    local function test_command_json()
      if vim.fn.has 'win32' == 1 then
        return 'go test .\\integration_tests\\ -v --json \r'
      else
        return 'go test integration_tests/*.go -v --json \r'
      end
    end

    require('go-test-t').new {
      term_test_command_format = term_test_command_format(),
      test_command_format_json = test_command_json(),
      user_command_prefix = 'Go',
    }
    vim.keymap.set('n', '<leader>T', ':GoTestTermView<CR>', { desc = 'Test: View enclosing test terminal' })

    require('go-test-t').new {
      user_command_prefix = 'Play',
    }
  end,
}
