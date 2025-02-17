local map = vim.keymap.set
local map_opt = function(opts)
  local opts = vim.tbl_deep_extend('force', opts, { noremap = true, silent = true })
  return opts
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
    vim.g.disable_tab_mapping = true

    local function map_accept_augment()
      map('i', '<C-l>', '<cmd>call augment#Accept()<CR>', { expr = false, desc = 'Accept Augment' })
    end

    map('n', '<localleader>ae', function()
      vim.cmd [[Augment enable]]
      vim.cmd [[Copilot disable]]
      map_accept_augment()
      print 'Augment enabled'
    end, map_opt { desc = '[A]ugment [E]nable' })

    map('n', '<localleader>ad', function()
      vim.cmd [[Augment disable]]
      vim.cmd [[Copilot enable]]
      Map_copilot()
      print 'Augment disabled'
    end, map_opt { desc = '[A]ugment [D]isable' })

    map('n', '<localleader>at', ':Augment chat-toggle<CR>', map_opt { desc = '[C]hat [T]oggle' })

    map({ 'n', 'v' }, '<localleader>ac', function()
      vim.cmd [[Augment enable]]
      vim.cmd [[Copilot disable]]
      vim.cmd [[Augment chat]]
    end, map_opt { desc = '[A]ugment [C]hat' })
  end,
}
