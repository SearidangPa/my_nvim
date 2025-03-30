local M = {}

M.new_prompt_pr_desc = function()
  -- Create new scratch buffer
  vim.cmd 'enew'
  vim.cmd 'setlocal buftype=nofile bufhidden=hide noswapfile'
  vim.cmd 'setlocal filetype=markdown'

  -- Execute the ai_pr_desc function and capture its output
  local output = vim.fn.system 'zsh -c "source ~/.zshrc && ai_pr_desc"'

  -- Insert the output at the beginning of the buffer
  local lines = vim.split(output, '\n')
  vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)

  -- Move cursor to the beginning of the buffer
  vim.cmd 'normal! gg'
end

vim.api.nvim_create_user_command('NewPromptPRDesc', M.new_prompt_pr_desc, {})

M.new_scratch_buf = function()
  vim.cmd 'enew'
  vim.cmd 'setlocal buftype=nofile bufhidden=hide noswapfile'
  vim.cmd 'setlocal filetype=markdown'
end
vim.api.nvim_create_user_command('NewScratch', M.new_scratch_buf, { desc = 'Start a scratch buffer' })

return M
