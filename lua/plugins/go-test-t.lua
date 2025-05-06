return {
  'SearidangPa/go-test-t.nvim',
  lazy = true,
  ft = 'go',
  event = 'WinEnter',
  dependencies = {
    'echasnovski/mini.nvim',
    'j-hui/fidget.nvim',
    'SearidangPa/terminal-multiplexer.nvim',
  },
  config = function()
    local go_test_prefix = 'go test'
    local cwd = vim.fn.getcwd()
    if string.match(cwd, 'drive') then
      go_test_prefix = 'MODE=staging UKS=others go test'
    end

    require('go-test-t').new {
      go_test_prefix = go_test_prefix,
      user_command_prefix = 'Go',
    }
    vim.keymap.set('n', '<leader>G', ':GoTestTerm<CR>', { desc = 'Test: View enclosing test terminal' })
    vim.keymap.set('n', '<leader>T', ':GoTestTermView<CR>', { desc = 'Test: View enclosing test terminal' })
  end,
}
