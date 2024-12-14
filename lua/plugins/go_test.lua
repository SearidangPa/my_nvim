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
          append_data(_, data)

          for _, line in ipairs(data) do
            if line == '' then
              goto continue
            end

            local decoded = vim.json.decode(line)
            if not decoded then
              goto continue
            end

            if decoded.Action == 'run' then
              print(string.format('Running %s', decoded.Action))
            end

            ::continue::
          end
        end,

        on_stderr = append_data,
      })
    end,
  })
end

vim.api.nvim_create_user_command('AutoRun', function()
  local bufnr = vim.fn.input 'Bufnr: '
  local command = { 'go', 'test', '-json', '-v', '-run', GetEnclosingFunctionName() }
  print('Running command: ' .. table.concat(command, ' '))
  -- local command = vim.split(vim.fn.input 'Command: ', ' ')
  attach_to_buffer(tonumber(bufnr), command)
end, {})

vim.keymap.set('n', '<leader>xr', function()
  vim.cmd 'AutoRun'
end, { desc = 'Auto run' })

return {}
