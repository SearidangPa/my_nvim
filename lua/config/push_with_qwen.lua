if vim.fn.has 'win32' == 1 then
  return {}
end

local push_with_qwen = {}
local qwen_terminal_name = 'git_push_with_qwen14b'
local push_cmd_str_14b = 'gaa && pg_14\r'
local push_cmd_str_7b = 'gaa && pg_7\r'
local start_ollama_command_str = 'start_ollama\r'

push_with_qwen._get_commit_message_and_time = function()
  local message = vim.fn.system 'git log -1 --pretty=%B'
  local time = vim.fn.system "git log -1 --pretty=%ad --date=format:'%Y-%m-%d %H:%M:%S'"
  return {
    message = vim.fn.trim(message),
    time = vim.fn.trim(time),
  }
end

push_with_qwen.push_with_qwen = function(push_cmd_str, model_name)
  require 'terminal-multiplexer'
  local terminal_multiplexer = require('config.terminals_daemon').terminal_multiplexer

  if vim.bo.filetype == 'go' then
    local async_make_job = require 'config.async_job'
    async_make_job.make_lint()
    async_make_job.make_all()
  end

  terminal_multiplexer:delete_terminal(qwen_terminal_name)
  terminal_multiplexer:toggle_float_terminal(qwen_terminal_name)

  ---@type FloatTermState
  local float_terminal_state = terminal_multiplexer:toggle_float_terminal(qwen_terminal_name)
  vim.api.nvim_chan_send(float_terminal_state.chan, push_cmd_str .. '\n')

  local make_notify = require('mini.notify').make_notify {}
  make_notify('Sent request to ' .. model_name)

  vim.api.nvim_buf_attach(float_terminal_state.bufnr, false, {
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
  vim.api.nvim_chan_send(float_terminal_state.chan, start_ollama_command_str .. '\n')
  vim.defer_fn(function()
    local output = vim.api.nvim_buf_get_lines(float_terminal_state.bufnr, 0, -1, false)
    local make_notify = require('mini.notify').make_notify {}
    make_notify(string.format('output:\n%s', table.concat(output, '\n')))
  end, 1000)
end

local function push_with_14b() push_with_qwen.push_with_qwen(push_cmd_str_14b, 'qwen14b') end

vim.api.nvim_create_user_command('StartOllama', push_with_qwen.start_ollama, {})
vim.keymap.set('n', '<leader>pq', push_with_14b, { silent = true, desc = '[P]ush with [Q]wen14b' })

return push_with_qwen
