if vim.fn.has 'win32' == 1 then
  return {}
end

local push_with_qwen = {}
local qwen_terminal_name = 'git_push_with_qwen14b'

push_with_qwen._get_commit_message_and_time = function()
  local message = vim.fn.system 'git log -1 --pretty=%B'
  local time = vim.fn.system "git log -1 --pretty=%ad --date=format:'%Y-%m-%d %H:%M:%S'"
  return {
    message = vim.fn.trim(message),
    time = vim.fn.trim(time),
  }
end

push_with_qwen.push_with_qwen = function()
  local terminal_multiplexer = require('config.terminals_daemon').terminal_multiplexer
  if vim.bo.filetype == 'go' then
    local async_make_job = require 'config.async_job'
    async_make_job.make_lint()
    async_make_job.make_all()
  end

  terminal_multiplexer:toggle_float_terminal(qwen_terminal_name)
  local float_terminal_state = terminal_multiplexer:toggle_float_terminal(qwen_terminal_name)

  assert(float_terminal_state, 'Failed to toggle float terminal')
  local push_command_str = 'gaa && pg_14\r'
  vim.api.nvim_chan_send(float_terminal_state.chan, push_command_str .. '\n')

  local make_notify = require('mini.notify').make_notify {}
  make_notify 'Sent request to push with Qwen14b'

  vim.api.nvim_buf_attach(float_terminal_state.buf, false, {
    on_lines = function(_, buf, _, first_line, last_line)
      local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)

      for _, line in ipairs(lines) do
        if string.match(line, 'To github.com:') then
          local commit_info_now = push_with_qwen._get_commit_message_and_time()
          make_notify(commit_info_now.message)
          return true
        elseif string.match(line, 'Error: could not connect to ollama app, is it running?') then
          make_notify('ollama app is not running', vim.log.levels.ERROR)
          return true
        end
      end

      return false
    end,
  })
end

push_with_qwen.start_ollama = function()
  local terminal_multiplexer = require('config.terminals_daemon').terminal_multiplexer
  terminal_multiplexer:toggle_float_terminal(qwen_terminal_name)
  local float_terminal_state = terminal_multiplexer:toggle_float_terminal(qwen_terminal_name)

  assert(float_terminal_state, 'Failed to toggle float terminal')
  local start_ollama_command_str = 'start_ollama\r'
  vim.api.nvim_chan_send(float_terminal_state.chan, start_ollama_command_str .. '\n')
  vim.defer_fn(function()
    local output = vim.api.nvim_buf_get_lines(float_terminal_state.buf, 0, -1, false)
    local make_notify = require('mini.notify').make_notify {}
    make_notify(string.format('output:\n%s', table.concat(output, '\n')))
  end, 1000)
end

vim.api.nvim_create_user_command('StartOllama', push_with_qwen.start_ollama, {})
vim.api.nvim_create_user_command('GitPushWithQwen14b', push_with_qwen.push_with_qwen, {})
vim.keymap.set('n', '<leader>pq', push_with_qwen.push_with_qwen, { silent = true, desc = '[P]ush with [Q]wen14b' })

return push_with_qwen
