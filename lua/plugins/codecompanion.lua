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
      adapter = {
        name = 'copilot',
      },
    },
    prompts = {
      {
        role = 'user',
        content = function(context)
          local code = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)
          if context.filetype == 'go' then
            return 'Add a documentation above the function. I want from 2-4 bullet points. Pay attention to the main ideas of the function.'
              .. 'I want it inside the /*  block above the function.'
              .. 'There should be in this format /*\n<your input\n*/'
              .. 'The first nonempty line should start with the function name and its purpose.'
              .. 'I do not want any empty line'
              .. 'You should not return any more star. The first line should not be a bullet point. \n\n```'
              .. '\n'
              .. code
              .. '\n```'
          elseif context.filetype == 'lua' then
            return 'Add a documentation above the function. I want from 2-4 bullet points. Pay attention to the main ideas of the code block.'
              .. 'I want it inside --[['
              .. ']]'
              .. '\n'
              .. code
              .. '\n```'
          end
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
  lazy = true,
  version = '*',
  event = 'VeryLazy',
  config = function()
    require('custom.fidget_spinner_for_ai'):init()
    require('codecompanion').setup {
      display = opts.displays,
      adapters = opts.adapters,
      prompt_library = opts.prompt_library,
      strategies = {
        chat = { adapter = 'copilot' },
        inline = { adapter = 'copilot' },
      },
    }
  end,
}
