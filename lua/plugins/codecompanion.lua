if vim.fn.has 'win32' == 1 then
  return {}
end

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
  ollama = function()
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
    description = 'Add documentation above the selected function',
    opts = {
      modes = { 'v' }, -- Only available in visual mode
      short_name = 'docfn',
      auto_submit = true,
      stop_context_insertion = true,
      placement = 'replace',
      ignore_system_prompt = true,
    },
    prompts = {
      {
        role = 'user',
        content = function(context)
          local code = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)
          return 'Add a documentation above the function. I want from 2-4 bullet points. Pay attention to the main ideas of the function.'
            .. 'I want it inside the /*  block above the function.'
            .. 'There should be in this format /*\n<your input\n*/'
            .. 'The first nonempty line should start with the function name and its purpose.'
            .. 'I do not want any empty line'
            .. 'You should not return any more star. The first line should not be a bullet point. \n\n```'
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
  event = 'VeryLazy',
  lazy = true,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'echasnovski/mini.diff',
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

    vim.keymap.set({ 'v', 'n' }, '<leader>ad', function()
      require('codecompanion').prompt 'docfn'
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
    end, { noremap = true, silent = true })

    vim.keymap.set({ 'v', 'n' }, '<leader>af', function()
      local util_find_func = require 'config.util_find_func'
      util_find_func.visual_function()
      vim.cmd [[normal! o]]
      require('codecompanion').prompt 'docfn'
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
    end, { noremap = true, silent = true, desc = '[A]dd [D]oc to function' })
  end,
}
