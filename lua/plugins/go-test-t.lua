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

    local function test_command()
      if vim.fn.has 'win32' == 1 then
        return 'go test .\\integration_tests\\ -v \r'
      else
        return 'go test integration_tests/*.go -v \r'
      end
    end

    require('go-test-t').new {
      test_command = test_command(),
      term_test_command_format = term_test_command_format(),
      user_command_prefix = 'Go',
    }

    vim.keymap.set('n', '<leader>T', ':GoTestTermView<CR>', { desc = 'Test: View enclosing test terminal' })
  end,
}
