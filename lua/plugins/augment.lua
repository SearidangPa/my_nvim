local augment_accept = function()
  local accept = vim.fn['augment#Accept']
  assert(accept, 'augment#Accept not found')
  local res = accept()
  vim.api.nvim_feedkeys(res, 'n', false)
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

    vim.keymap.set('i', '<C-l>', augment_accept, { expr = true, silent = true, desc = 'Accept Augment Suggestion' })
  end,
}
