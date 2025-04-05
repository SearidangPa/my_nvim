return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'echasnovski/mini.diff',
    'zbirenbaum/copilot.lua',
    'j-hui/fidget.nvim',
  },
  init = function()
    -- Set up the fidget spinner for CodeCompanion
    require('config.fidget_spinner_for_ai'):init()
  end,

  config = function()
    require('codecompanion').setup {
      display = {
        diff = {
          enable = true,
          provider = 'mini_diff', -- default|mini_diff
        },
      },
      -- 1. Specify which adapter to use for each strategy (chat vs inline):
      strategies = {
        chat = { adapter = 'copilot', opts = {} },
        inline = { adapter = 'ollama', opts = {} },
      },
      -- 2. Configure the Ollama adapter to use the Qwen-2.5 Coder 14B model by default:
      adapters = {
        copilot = function()
          -- This adapter will auto-detect your Copilot setup.
          return require('codecompanion.adapters').extend('copilot', {})
        end,
        ollama = function()
          return require('codecompanion.adapters').extend('ollama', {
            -- Set the default model for Ollama:
            schema = {
              model = { default = 'qwen2.5-coder:7b' },
            },
            -- (No API key needed for local Ollama; if remote or secured, you could add env = { api_key = "..."} here)
          })
        end,

        ollama14b = function()
          return require('codecompanion.adapters').extend('ollama', {
            -- Set the default model for Ollama:
            schema = {
              model = { default = 'qwen2.5-coder:14b' },
            },
            -- (No API key needed for local Ollama; if remote or secured, you could add env = { api_key = "..."} here)
          })
        end,
      },
    }
  end,
}
