local M = {}
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local terminal_multiplexer = require('config.terminal_multiplexer').new()

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

-- === Git Push with Qwen14b ===
local terminal_name = 'git_push_with_qwen14b'

local function get_commit_message_and_time()
  local message = vim.fn.system 'git log -1 --pretty=%B'
  local time = vim.fn.system "git log -1 --pretty=%ad --date=format:'%Y-%m-%d %H:%M:%S'"

  return {
    message = vim.fn.trim(message),
    time = vim.fn.trim(time),
  }
end

local push_all_with_qwen = function(command_str) end

local function push_with_qwen()
  local command_str = 'gaa && pg_14\r'
  print(command_str)
  push_all_with_qwen(command_str)

  local async_make_job = require 'config.async_make_job'
  async_make_job.make_lint()
  async_make_job.make_all()

  terminal_multiplexer:toggle_float_terminal(terminal_name)
  local float_terminal_state = terminal_multiplexer:toggle_float_terminal(terminal_name)

  assert(float_terminal_state, 'Failed to toggle float terminal')
  local commit_info_prev = get_commit_message_and_time()
  vim.api.nvim_chan_send(float_terminal_state.chan, command_str .. '\n')
  make_notify 'Sent request to push with Qwen14b'

  vim.api.nvim_buf_attach(float_terminal_state.buf, false, {
    on_lines = function(_, buf, _, first_line, last_line)
      local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)

      for _, line in ipairs(lines) do
        if string.match(line, 'To github.com:') then
          local commit_info_now = get_commit_message_and_time()
          if commit_info_now.message ~= commit_info_prev.message then
            make_notify(commit_info_now.message)
            return true
          end
        end
      end

      return false
    end,
  })
end

vim.api.nvim_create_user_command('GitPushWithQwen14b', push_with_qwen, {})
vim.keymap.set('n', '<leader>pq', push_with_qwen, { silent = true, desc = '[P]ush with [Q]wen14b' })
vim.api.nvim_create_user_command('QwenTermToggle', function() terminal_multiplexer:toggle_float_terminal(terminal_name) end, {})

vim.api.nvim_create_user_command('LastCommitMessage', function()
  local commit_info = get_commit_message_and_time()
  print(string.format('Last commit message: %s', commit_info.message))
  print(string.format('Time: %s', commit_info.time))
end, {})
return M
