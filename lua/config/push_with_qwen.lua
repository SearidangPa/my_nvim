if vim.fn.has 'win32' == 1 then
  return {}
end

-- === Git Push with Qwen14b ===
local M = {}

local pq_term_name = 'git_push_with_qwen14b'

M._get_commit_message_and_time = function()
  local message = vim.fn.system 'git log -1 --pretty=%B'
  local time = vim.fn.system "git log -1 --pretty=%ad --date=format:'%Y-%m-%d %H:%M:%S'"

  return {
    message = vim.fn.trim(message),
    time = vim.fn.trim(time),
  }
end

M.push_with_qwen = function()
  local terminal_multiplexer = require('config.terminals_daemon').terminal_multiplexer
  if vim.bo.filetype == 'go' then
    local async_make_job = require 'config.async_make_job'
    async_make_job.make_lint()
    async_make_job.make_all()
  end

  terminal_multiplexer:delete_terminal(pq_term_name)
  terminal_multiplexer:toggle_float_terminal(pq_term_name)
  local float_terminal_state = terminal_multiplexer:toggle_float_terminal(pq_term_name)

  assert(float_terminal_state, 'Failed to toggle float terminal')
  local command_str = 'gaa && pg_14\r'
  vim.api.nvim_chan_send(float_terminal_state.chan, command_str .. '\n')
  local make_notify = require('mini.notify').make_notify {}
  make_notify 'Sent request to push with Qwen14b'

  vim.api.nvim_buf_attach(float_terminal_state.buf, false, {
    on_lines = function(_, buf, _, first_line, last_line)
      local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)

      for _, line in ipairs(lines) do
        if string.match(line, 'To github.com:') then
          local commit_info_now = M._get_commit_message_and_time()
          make_notify(commit_info_now.message)
          return true
        end
      end

      return false
    end,
  })
end

vim.api.nvim_create_user_command('GitPushWithQwen14b', M.push_with_qwen, {})
vim.keymap.set('n', '<leader>pq', M.push_with_qwen, { silent = true, desc = '[P]ush with [Q]wen14b' })

return M
