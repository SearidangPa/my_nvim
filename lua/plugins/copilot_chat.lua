if vim.fn.has'win32' == 1 then
  return {}
end

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
          prompt = 'Generate a mermaid diagram for the following flow description',
          system_prompt = [[You are a code-focused AI programming assistant that specializes in practical software engineering solutions.]],
          description = 'Mermaid diagram',
        },
      },
    },
  },
}
