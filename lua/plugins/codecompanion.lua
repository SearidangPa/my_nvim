local opts = {}
opts.displays = {
  inline = {
    layout = 'vertical',
  },
  diff = {
    enable = true,
    provider = 'mini_diff',
  },
}
opts.adapters = {
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
}

opts.prompt_library = {
  ['Document Selected Function'] = {
    strategy = 'inline',
    description = 'Add documentation for a selected function including LSP references',
    opts = {
      mapping = '<LocalLeader>dd', -- Key mapping to trigger the prompt
      modes = { 'v' }, -- Only available in visual mode
      short_name = 'docfn',
      auto_submit = true,
      stop_context_insertion = true,
    },
    prompts = {
      {
        role = 'system',
        content = function(context)
          return 'You are an expert documentation writer. '
            .. 'Using the provided code, add detailed documentation for the code. I want at most 4 bullet points, and i want you to focus on the higher level flows'
        end,
      },
      {
        role = 'user',
        content = function(context)
          local code = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)
          return '#lsp Add document the following code :\n\n```' .. context.filetype .. '\n' .. code .. '\n```'
        end,
        opts = {
          contains_code = true,
        },
      },
    },
  },
}

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
      display = opts.displays,
      adapters = opts.adapters,
      prompt_library = opts.prompt_library,
      strategies = {
        chat = { adapter = 'copilot' },
        inline = { adapter = 'copilot' },
      },
    }
    vim.keymap.set('v', '<leader>ad', function() require('codecompanion').prompt 'docfn' end, { noremap = true, silent = true })
  end,
}
