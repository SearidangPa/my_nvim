return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'leoluz/nvim-dap-go',
    'rcarriga/nvim-dap-ui',
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
    require('dap-go').setup()
    local dapui = require 'dapui'
    dapui.setup {
      layouts = {
        {
          elements = {
            {
              id = 'scopes',
              size = 0.5,
            },
            { id = 'breakpoints', size = 0.1 },
            { id = 'stacks', size = 0.4 },
          },
          size = 40,
          position = 'left',
        },
        {
          elements = {
            'repl',
          },
          size = 10,
          position = 'bottom',
        },
      },
    }
    vim.keymap.set('n', '<localleader><localleader>', function()
      dapui.eval(nil, { enter = true })
    end)
    vim.keymap.set('n', '<space>td', function()
      require('dap-go').debug_test()
    end, { desc = 'Debug test' })

    vim.keymap.set('n', '<space>b', dap.toggle_breakpoint, { desc = 'Toggle breakpoint' })
    vim.keymap.set('n', '<space>gb', dap.run_to_cursor, { desc = 'Run to cursor' })
    vim.keymap.set('n', '<D-g>', dap.continue, { desc = 'Continue' })
    vim.keymap.set('n', '<D-i>', dap.step_into, { desc = 'Step into' })
    vim.keymap.set('n', '<D-o>', dap.step_out, { desc = 'Step out' })
    vim.keymap.set('n', '<D-j>', dap.step_over, { desc = 'next' })

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end
    vim.keymap.set('n', '<space>du', require('dapui').toggle, { desc = 'Toggle DAP UI' })
  end,
}
