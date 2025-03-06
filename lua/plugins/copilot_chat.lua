return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'github/copilot.vim' }, -- or zbirenbaum/copilot.lua
      { 'nvim-lua/plenary.nvim', branch = 'master' }, -- for curl, log and async functions
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    opts = {
      model = 'claude-3.7-sonnet',
      prompts = {
        Docs = {
          prompt = 'Add documentation to the selected code. Focus on the flow and when error is return. As concise as possible. Avoid empty and vague words. I want specific details. I want it in /*\n*/ format only if it is longer than 5 lines. I want at most 5 lines in total',
        },
      },
    },
  },
}
