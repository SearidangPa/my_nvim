-- === Git Push with Qwen14b ===
local terminal_name = 'git_push_with_qwen14b'
local make_notify = require('mini.notify').make_notify {}
local terminal_multiplexer = require('config.terminals_daemon').terminal_multiplexer

local function get_commit_message_and_time()
  local message = vim.fn.system 'git log -1 --pretty=%B'
  local time = vim.fn.system "git log -1 --pretty=%ad --date=format:'%Y-%m-%d %H:%M:%S'"

  return {
    message = vim.fn.trim(message),
    time = vim.fn.trim(time),
  }
end

local function push_with_qwen()
  local async_make_job = require 'config.async_make_job'
  async_make_job.make_lint()
  async_make_job.make_all()
  local terminals_test = require 'config.terminals_test'
  terminals_test.test_list()

  terminal_multiplexer:toggle_float_terminal(terminal_name)
  local float_terminal_state = terminal_multiplexer:toggle_float_terminal(terminal_name)

  assert(float_terminal_state, 'Failed to toggle float terminal')
  local commit_info_prev = get_commit_message_and_time()
  local command_str = 'gaa && pg_14\r'
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
