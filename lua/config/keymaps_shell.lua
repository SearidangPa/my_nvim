vim.api.nvim_create_user_command('Make', function()
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j all' }
  else
    cmd = { 'make', '-j', 'all' }
  end

  local errors = {}
  local job_id = vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      if data and #data > 0 then
        vim.list_extend(errors, data)
      end
    end,

    on_exit = function(_, code)
      if code == 0 then
        vim.notify('Make completed successfully!', vim.log.levels.INFO)
        return
      end
      vim.notify('Make failed with exit code ' .. code, vim.log.levels.ERROR)
      vim.fn.setqflist({}, ' ', {
        title = 'Make Errors',
        lines = errors,
      })
      vim.cmd 'copen'
    end,
  })

  if job_id <= 0 then
    vim.notify('Failed to start the Make command', vim.log.levels.ERROR)
  end
end, {})

vim.api.nvim_create_user_command('GoModTidy', function()
  local cmd = { 'go', 'mod', 'tidy' }

  local errors = {}
  local job_id = vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      if data and #data > 0 then
        vim.list_extend(errors, data)
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify('GoModTidy completed successfully!', vim.log.levels.INFO)
      else
        vim.notify('GoModTidy failed with exit code ' .. code, vim.log.levels.ERROR)
        vim.fn.setqflist({}, ' ', {
          title = 'GoModTidy Errors',
          lines = errors,
        })
        vim.cmd 'copen'
      end
    end,
  })

  if job_id <= 0 then
    vim.notify('Failed to start the GoModTidy command', vim.log.levels.ERROR)
  end
end, {})

vim.keymap.set('n', '<leader>gmt', ':GoModTidy<CR>', { desc = '[G]o [M]od [T]idy' })
vim.api.nvim_set_keymap('n', '<leader>xx', '<cmd>source % <CR>', { noremap = true, silent = true, desc = 'source %' })
vim.keymap.set('n', '<leader>rm', '<cmd>messages<CR>', { desc = 'read messages' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
if vim.fn.has 'win32' == 1 then
  vim.keymap.set('n', '<leader>tt', '<cmd>term powershell.exe<CR>a', { desc = 'Open terminal' })
else
  vim.keymap.set('n', '<leader>tt', '<cmd>term<CR>a', { desc = 'Open terminal' })
end
vim.keymap.set('n', '<leader>ma', ':Make<CR>', { desc = 'Run make all in the background' })
vim.keymap.set('n', '<leader>mc', ':messages clear<CR>', { desc = '[C]lear [m]essages' })
vim.keymap.set('n', '<leader>rl', function()
  vim.cmd 'LspRestart'
end, { noremap = true, desc = '[R]estart [L]SP' })
return {}
