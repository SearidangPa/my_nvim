local M = {}
local make_notify = require('mini.notify').make_notify {}
local terminal_multiplexer = require('terminal-multiplexer').new {
  powershell = true,
}
M.terminal_multiplexer = terminal_multiplexer

M.exec_command = function(command, title)
  terminal_multiplexer:toggle_float_terminal(title)
  local current_float_term_state = terminal_multiplexer:toggle_float_terminal(title)
  assert(current_float_term_state, 'Failed to toggle float terminal')
  vim.api.nvim_chan_send(current_float_term_state.chan, command .. '\n')
  make_notify(string.format('running %s daemon', title))

  vim.defer_fn(function()
    local output = vim.api.nvim_buf_get_lines(current_float_term_state.buf, 0, -1, false)
    make_notify(string.format('output:\n%s', table.concat(output, '\n')))
  end, 3000)
end

local function run_drive()
  if vim.fn.has 'win32' == 1 then
    M.exec_command('dr; rds\r', 'drive')
  else
    M.exec_command('dr && kill_port_4420 && ./bin/client --stdout --onlyUserIDs', 'drive')
  end
end

-- === cloud drive ===
local run_cloud_drive_command = 'm; std\r'
local cloud_drive_terminal_name = 'cloud drive'
local function run_cloud_drive()
  terminal_multiplexer:delete_terminal(cloud_drive_terminal_name)
  M.exec_command(run_cloud_drive_command, cloud_drive_terminal_name)
end

vim.api.nvim_create_user_command('RunCloudDrive', run_cloud_drive, {})
vim.api.nvim_create_user_command('RunDrive', run_drive, {})

vim.keymap.set('n', '<leader>st', function() terminal_multiplexer:search_terminal() end, { desc = '[S]earch [D]aemon terminals' })

-- === gh_actions ===
local daemon_terminal_name = 'gh actions'
vim.api.nvim_create_user_command('GhActionsCheckRetry', function() M.exec_command('gh-check-with-rerun', daemon_terminal_name) end, {})
vim.api.nvim_create_user_command('GhActionsCheckStatus', function() M.exec_command('gh-check-status', daemon_terminal_name) end, {})
vim.api.nvim_create_user_command('GhActionsTerminalToggle', function() terminal_multiplexer:toggle_float_terminal(daemon_terminal_name) end, {})

vim.api.nvim_create_user_command('GhActionsRetryTillSuccess', function()
  local interval_minutes = 10
  M.exec_command(string.format('retry_until_success %d', interval_minutes), daemon_terminal_name)
end, {})

return M
