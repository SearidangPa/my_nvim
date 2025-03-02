return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'leoluz/nvim-dap-go',
    { 'igorlfs/nvim-dap-view', opts = {} },
    'theHamsta/nvim-dap-virtual-text',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
  },
  config = function()
    local dap = require 'dap'
    dap.configurations.go = {
      {
        type = 'go',
        name = 'Debug integration test :D',
        request = 'launch',
        mode = 'test',
        program = './integration_tests',
      },
    }

    dap.adapters.delve = {
      type = 'server',
      host = '127.0.0.1',
      port = 38697,
    }

    require('dap-go').setup()
    vim.keymap.set('n', '<space>td', function()
      require('dap-go').debug_test()
    end, { desc = 'Debug test' })

    vim.keymap.set('n', '<space>b', dap.toggle_breakpoint)
    vim.keymap.set('n', '<space>gb', dap.run_to_cursor)

    vim.keymap.set('n', '<localleader>c', dap.continue)
    vim.keymap.set('n', '<D-i>', dap.step_into)
    vim.keymap.set('n', '<D-o>', dap.step_out)
    vim.keymap.set('n', '<D-j', dap.step_over)
  end,
}
