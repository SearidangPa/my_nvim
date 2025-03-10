local M = {}
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

local TerminalMultiplexer = require 'config.terminal_multiplexer'
local terminal_multiplexer = TerminalMultiplexer.new()

local exec_command = function(command, title)
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

-- === Commands and keymaps ===
vim.api.nvim_create_user_command('RunDrive', function() exec_command('dr;rds', 'drive') end, {})
vim.api.nvim_create_user_command('RunCloudDrive', function() exec_command('m; std', 'cloud drive') end, {})

vim.keymap.set('n', '<leader>sd', function() terminal_multiplexer.search_terminal() end, { desc = '[S]earch [D]aemon terminals' })
vim.keymap.set('n', '<leader>dc', function() exec_command('m; std', 'cloud drive') end, { desc = '[D]aemon [C]loud drive' })

vim.keymap.set('n', '<leader>dr', function()
  if vim.fn.has 'win32' == 1 then
    exec_command('dr;rds\r', 'drive')
  else
    exec_command('dr && kill_port_4420 && ./bin/client --stdout --onlyUserIDs spa@preveil.com', 'drive')
  end
end, { silent = true, desc = '[D]aemon [R]un drive' })

vim.keymap.set('n', '<leader>da', function()
  exec_command('dr;rds\r', 'drive')
  exec_command('m; std', 'cloud drive')
  M.navigate_daemon_terminal(1)
end, { desc = '[D]aemon [A]ll' })

return M
