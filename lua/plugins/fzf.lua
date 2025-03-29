return {
  'ibhagwan/fzf-lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    vim.keymap.set('n', '<leader>sb', function()
      require('fzf-lua').git_branches {
        -- cmd = 'git branch --all --color',
        -- actions = {
        --   ['default'] = function(selected)
        --     local branch = selected[1]:match '([^%s]+)$'
        --     vim.cmd('!git switch ' .. branch)
        --   end,
        -- },
      }
    end, { noremap = true, silent = true })
  end,
}
