return {
  'SearidangPa/go-test-t.nvim',
  lazy = true,
  ft = 'go',
  config = function()
    local go_test_prefix = 'go test'
    local cwd = vim.fn.getcwd()
    if string.match(cwd, 'drive') then
      go_test_prefix = 'MODE=staging UKS=others go test'
    end

    local go_test_t = require('go-test-t').new {
      go_test_prefix = go_test_prefix,
      user_command_prefix = 'Go',
    }

    vim.keymap.set('n', '<localleader>g', ':GoTestTerm<CR>', { desc = 'Go testies' })

    vim.keymap.set('n', '<localleader>t', function()
      require 'terminal-multiplexer'
      local util_lsp = require 'go-test-t.util_lsp'
      local test_name = go_test_t.term_tester.terminal_multiplexer.last_terminal_name
      util_lsp.action_from_test_name(test_name, function(lsp_param)
        local filepath = lsp_param.filepath
        local test_line = lsp_param.test_line
        vim.cmd('edit ' .. filepath)

        if test_line then
          local pos = { test_line, 0 }
          vim.api.nvim_win_set_cursor(0, pos)
          vim.cmd 'normal! zz'
        end
      end)
    end, { desc = 'jump to last test in code' })
  end,
}
