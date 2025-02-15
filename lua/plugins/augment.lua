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
  end,
}
