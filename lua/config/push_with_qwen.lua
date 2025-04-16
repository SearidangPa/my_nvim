if vim.fn.has 'win32' == 1 then
  return {}
end

local push_with_qwen = {}

local pq_term_name = 'git_push_with_qwen14b'

push_with_qwen._get_commit_message_and_time = function()
  local message = vim.fn.system 'git log -1 --pretty=%B'
  local time = vim.fn.system "git log -1 --pretty=%ad --date=format:'%Y-%m-%d %H:%M:%S'"

  return {
    message = vim.fn.trim(message),
    time = vim.fn.trim(time),
  }
end

push_with_qwen.push_with_qwen = function()
  local make_notify = require('mini.notify').make_notify {}
  if not push_with_qwen._check_ollama_running() then
    make_notify('Error: Ollama is not running', vim.log.levels.ERROR)
    return
  end
  local terminal_multiplexer = require('config.terminals_daemon').terminal_multiplexer
  if vim.bo.filetype == 'go' then
    local async_make_job = require 'config.async_job'
    async_make_job.make_lint()
    async_make_job.make_all()
  end

  terminal_multiplexer:delete_terminal(pq_term_name)
  terminal_multiplexer:toggle_float_terminal(pq_term_name)
  local float_terminal_state = terminal_multiplexer:toggle_float_terminal(pq_term_name)

  assert(float_terminal_state, 'Failed to toggle float terminal')
  local command_str = 'gaa && pg_14\r'
  vim.api.nvim_chan_send(float_terminal_state.chan, command_str .. '\n')
  make_notify 'Sent request to push with Qwen14b'

  vim.api.nvim_buf_attach(float_terminal_state.buf, false, {
    on_lines = function(_, buf, _, first_line, last_line)
      local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)

      for _, line in ipairs(lines) do
        if string.match(line, 'To github.com:') then
          local commit_info_now = push_with_qwen._get_commit_message_and_time()
          make_notify(commit_info_now.message)
          return true
        end
      end

      return false
    end,
  })
end

push_with_qwen._check_ollama_running = function()
  local exit_code = os.execute 'pgrep -f ollama >/dev/null 2>&1'
  if exit_code == 0 then
    return true
  end
  local handle = io.popen "curl -s -m 2 -o /dev/null -w '%{http_code}' http://localhost:11434/api/health 2>/dev/null || echo 'failed'"
  assert(handle, 'Failed to run curl command')
  local result = handle:read '*a'
  handle:close()

  return result == '200'
end

vim.api.nvim_create_user_command('GitPushWithQwen14b', push_with_qwen.push_with_qwen, {})
vim.keymap.set('n', '<leader>pq', push_with_qwen.push_with_qwen, { silent = true, desc = '[P]ush with [Q]wen14b' })

return push_with_qwen
