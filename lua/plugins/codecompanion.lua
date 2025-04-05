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
    description = 'Add documentation for the selected function',
    opts = {
      modes = { 'v' }, -- Only available in visual mode
      short_name = 'docfn',
      auto_submit = true,
      stop_context_insertion = true,
      placement = 'replace',
    },
    prompts = {
      {
        role = 'system',
        content = function(context) return 'You are an expert documentation writer.' end,
      },
      {
        role = 'user',
        content = function(context)
          local code = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)
          return 'I want at most 4 bullet points, and i want you to focus on the higher level flows and its purpose. I want it inside the /*  block.'
            .. 'I do not want any empty new line after the first line.'
            .. 'You should not return any more star. The first line should not be a bullet point. Add document above the following code :\n\n```'
            .. context.filetype
            .. '\n'
            .. code
            .. '\n```'
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

    local function visual_function()
      local func_node = Nearest_func_node()
      local start_row, start_col, end_row, end_col = func_node:range()
      vim.cmd 'normal! v'
      vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
      vim.cmd 'normal! o'
      vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
    end

    vim.keymap.set({ 'v', 'n' }, '<leader>ad', function()
      visual_function()
      require('codecompanion').prompt 'docfn'
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
      vim.cmd [[wa]]
    end, { noremap = true, silent = true })
  end,
}
