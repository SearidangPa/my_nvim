local output = {}
local errors = {}

local create_user_command = function(cmd, invokeStr)
  output = {}
  errors = {}
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        table.insert(output, line)
      end
    end,

    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        table.insert(errors, line)
      end
    end,

    on_exit = function(_, code)
      if code ~= 0 then
        local notif = string.format('%s failed with exit code %d', invokeStr, code)
        vim.notify(notif, vim.log.levels.ERROR)
        return
      end
      local notif = string.format('%s completed successfully', invokeStr)
      vim.notify(notif, vim.log.levels.INFO)
    end,
  })

  if job_id <= 0 then
    vim.notify('Failed to start the Make command', vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_user_command('Make', function()
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j all' }
  else
    cmd = { 'make', '-j', 'all' }
  end
  create_user_command(cmd, 'Make')
end, {})

vim.api.nvim_create_user_command('GoModTidy', function()
  local cmd = { 'go', 'mod', 'tidy' }
  create_user_command(cmd, 'GoModTidy')
end, {})

vim.api.nvim_create_user_command('ViewOutput', function()
  Create_floating_window(output, 0, -1)
end, {})

vim.api.nvim_create_user_command('ViewErrors', function()
  Create_floating_window(errors, 0, -1)
end, {})

vim.api.nvim_set_keymap('n', '<leader>xx', '<cmd>source % <CR>', { noremap = true, silent = true, desc = 'source %' })
vim.keymap.set('n', '<leader>rm', '<cmd>messages<CR>', { desc = 'read messages' })
vim.keymap.set('n', '<leader>mc', ':messages clear<CR>', { desc = '[C]lear [m]essages' })
vim.keymap.set('n', '<leader>ma', ':Make<CR>', { desc = 'Run make all in the background' })

return {}
