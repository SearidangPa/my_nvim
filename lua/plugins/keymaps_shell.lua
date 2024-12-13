vim.api.nvim_create_user_command('Make', function()
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j all' }
  else
    cmd = { 'make', '-j', 'all' }
  end

  local output = {}
  local errors = {}
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        vim.list_extend(output, data)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        vim.list_extend(errors, data)
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify('Make completed successfully!', vim.log.levels.INFO)
      else
        vim.notify('Make failed with exit code ' .. code, vim.log.levels.ERROR)
        -- Populate the quickfix list with errors
        vim.fn.setqflist({}, ' ', {
          title = 'Make Errors',
          lines = errors,
        })
        -- Open the quickfix window and jump to the first error
        vim.cmd 'copen'
      end
    end,
  })

  if job_id <= 0 then
    vim.notify('Failed to start the Make command', vim.log.levels.ERROR)
  end
end, {})

vim.keymap.set('n', '<leader>m', ':Make<CR>', { desc = 'Run make in the background' })

vim.api.nvim_create_user_command('GoModTidy', function()
  vim.cmd [[!go mod tidy]]
end, { desc = 'Run go mod tidy' })
vim.keymap.set('n', '<leader>gmt', ':GoModTidy<CR>', { desc = '[G]o [M]od [T]idy' })

-- LspStop
vim.keymap.set('n', '<leader>gs', ':LspStop<CR>', { desc = 'Stop LSP' })

-- lua
vim.api.nvim_set_keymap('n', '<leader>x', '<cmd>source % <CR>', { noremap = true, silent = true, desc = 'source %' })

-- lsp
vim.api.nvim_set_keymap('n', '<m-r>', ':LspRestart<CR>', { desc = 'Restart LSP' })
vim.api.nvim_set_keymap('n', '<m-q>', ':LspStop', { desc = 'Stop LSP' })

-- terminal
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

if vim.fn.has 'win32' == 1 then
  vim.keymap.set('n', '<leader>tt', '<cmd>term powershell.exe<CR>a', { desc = 'Open terminal' })
else
  vim.keymap.set('n', '<leader>tt', '<cmd>term<CR>a', { desc = 'Open terminal' })
end

return {}
