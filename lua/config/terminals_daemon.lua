local M = {}
local make_notify = require('mini.notify').make_notify {}
local terminal_multiplexer = require('config.terminal_multiplexer').new()
M.terminal_multiplexer = terminal_multiplexer

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

local function run_drive()
  if vim.fn.has 'win32' == 1 then
    exec_command('dr;rds\r', 'drive')
  else
    exec_command('dr && kill_port_4420 && ./bin/client --stdout --onlyUserIDs', 'drive')
  end
end

-- === Commands and keymaps ===
vim.api.nvim_create_user_command('RunDrive', run_drive, {})
vim.api.nvim_create_user_command('RunCloudDrive', function() exec_command('m; std', 'cloud drive') end, {})
vim.keymap.set('n', '<leader>dr', run_drive, { silent = true, desc = '[D]aemon [R]un drive' })
vim.keymap.set('n', '<leader>dc', function() exec_command('m; std', 'cloud drive') end, { desc = '[D]aemon [C]loud drive' })
vim.keymap.set('n', '<leader>sd', function() terminal_multiplexer:search_terminal() end, { desc = '[S]earch [D]aemon terminals' })

return M
