return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'github/copilot.vim' }, -- or zbirenbaum/copilot.lua
      { 'nvim-lua/plenary.nvim', branch = 'master' }, -- for curl, log and async functions
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    opts = {
      model = 'Claude 3.7 Sonnet (Preview) (copilot:claude-3.7-sonnet)',
      prompts = {
        MyCustomPrompt = {
          prompt = 'Explain how it works.',
          system_prompt = 'You are very good at explaining stuff',
          mapping = '<leader>ccmc',
          description = 'My custom prompt description',
        },
      },
    },
  },
}
