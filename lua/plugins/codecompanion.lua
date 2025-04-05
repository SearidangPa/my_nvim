return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'echasnovski/mini.diff',
    'copilot.lua',
    'j-hui/fidget.nvim',
  },
  init = function() require('config.fidget_spinner_for_ai'):init() end,

  config = function()
    require('codecompanion').setup {
      display = {
        inline = {
          layout = 'vertical',
        },
        diff = {
          enable = true,
          provider = 'mini_diff',
        },
      },
      strategies = {
        chat = { adapter = 'copilot' },
        inline = { adapter = 'copilot' },
      },
      adapters = {
        copilot = function() return require('codecompanion.adapters').extend('copilot', {}) end,

        ollama7b = function()
          return require('codecompanion.adapters').extend('ollama', {
            schema = {
              model = { default = 'qwen2.5-coder:7b' },
            },
          })
        end,

        ollama14b = function()
          return require('codecompanion.adapters').extend('ollama', {
            schema = {
              model = { default = 'qwen2.5-coder:14b' },
            },
          })
        end,
      },
    }
    vim.keymap.set('n', '<leader>ad', function() require('codecompanion').prompt 'docs' end, { noremap = true, silent = true })
  end,
}
