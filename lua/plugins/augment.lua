local map = vim.keymap.set
local map_opt = function(desc)
  return { noremap = true, silent = true, desc = desc }
end

return {
  'augmentcode/augment.vim',
  config = function()
    vim.g.augment_workspace_folders = {
      '~/Documents/windows',
      '~/Documents/drive',
      '~/Documents/drive-terminal',
      '~/.config/nvim',
    }
    vim.cmd [[:Augment disable]]

    local function map_accept_augment()
      vim.keymap.set('i', '<C-l>', function()
        local accept = vim.fn['augment#Accept']
        if not accept then
          return
        end
        local res = accept()
        vim.api.nvim_feedkeys(res, 'n', false)
      end, { expr = true, silent = true, desc = 'Accept Augment' })
    end

    map('n', '<leader>ae', function()
      vim.cmd [[Augment enable]]
      vim.cmd [[Copilot disable]]
      map_accept_augment()
    end, map_opt '[A]ugment [E]nable')

    map('n', '<leader>ad', function()
      vim.cmd [[Augment disable]]
      vim.cmd [[Copilot enable]]
      Map_copilot()
    end, map_opt '[A]ugment [D]isable')

    map('n', '<leader>at', ':Augment chat-toggle<CR>', map_opt '[C]hat [T]oggle')
    map({ 'n', 'v' }, '<leader>ac', function()
      vim.cmd [[Augment enable]]
      vim.cmd [[Copilot disable]]
      vim.cmd [[Augment chat]]
    end, map_opt '[A]ugment [C]hat')
  end,
}
