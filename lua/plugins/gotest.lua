local attach_to_buffer = function(bufnr, command)
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup('reallyCool', { clear = true }),
    pattern = '*.go',
    callback = function()
      local append_data = function(_, data)
        if data then
          vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
        end
      end
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'output of main.go' })
      vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          if not data then
            return
          end
        end,
        on_stderr = append_data,
      })
    end,
  })
end

vim.api.nvim_create_user_command('AutoRun', function()
  local bufnr = vim.fn.input 'Bufnr: '
  local command = vim.split(vim.fn.input 'Command: ', ' ')
  attach_to_buffer(tonumber(bufnr), command)
end, {})

return {}
