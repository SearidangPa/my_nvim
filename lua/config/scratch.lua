local M = {}

local function new_scratch_buf()
  vim.cmd 'enew'
  vim.cmd 'setlocal buftype=nofile bufhidden=hide noswapfile'
  vim.cmd 'setlocal filetype=markdown'
end

vim.api.nvim_create_user_command('NewScratch', new_scratch_buf, { desc = 'Start a scratch buffer' })
return M
