local M = {}
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

local qwen_floating_term_state = {
  buf = -1,
  win = -1,
  chan = 0,
}

local function create_qwen_floating_window(buf_input)
  buf_input = buf_input or -1
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local row = math.floor((vim.o.columns - width))
  local col = math.floor((vim.o.lines - height))

  local buf = nil
  if buf_input == -1 then
    buf = vim.api.nvim_create_buf(false, true)
  else
    buf = buf_input
  end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  return buf, win
end

local toggle_qwen_floating_terminal = function()
  if vim.api.nvim_win_is_valid(qwen_floating_term_state.win) then
    vim.api.nvim_win_hide(qwen_floating_term_state.win)
    return
  end

  qwen_floating_term_state.buf, qwen_floating_term_state.win = create_qwen_floating_window(qwen_floating_term_state.buf)
  if vim.bo[qwen_floating_term_state.buf].buftype ~= 'terminal' then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term 'powershell.exe'
    else
      vim.cmd.term()
    end

    qwen_floating_term_state.chan = vim.bo.channel
  end
end

local function get_commit_message_and_time()
  local message = vim.fn.system 'git log -1 --pretty=%B'
  local time = vim.fn.system "git log -1 --pretty=%ad --date=format:'%Y-%m-%d %H:%M:%S'"

  return {
    message = vim.fn.trim(message),
    time = vim.fn.trim(time),
  }
end

local push_all_with_qwen = function(command_str)
  toggle_qwen_floating_terminal()
  toggle_qwen_floating_terminal()
  local commit_info_prev = get_commit_message_and_time()
  vim.api.nvim_chan_send(qwen_floating_term_state.chan, command_str .. '\n')
  make_notify 'Sent request to push with Qwen14b'

  vim.api.nvim_buf_attach(qwen_floating_term_state.buf, false, {
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

vim.api.nvim_create_user_command('GitPushWithQwen14b', function()
  local async_make_job = require 'config.async_make_job'
  local command_str = 'git add . && pg_14'
  push_all_with_qwen(command_str)
  async_make_job.make_lint()
  async_make_job.make_all()
end, {})

vim.api.nvim_create_user_command('QwenTermToggle', toggle_qwen_floating_terminal, {})
vim.api.nvim_create_user_command('LastCommitMessage', function()
  local commit_info = get_commit_message_and_time()
  print(string.format('Last commit message: %s', commit_info.message))
  print(string.format('Time: %s', commit_info.time))
end, {})

vim.keymap.set('n', '<leader>pq', ':GitPushWithQwen14b<CR>', { silent = true, desc = '[P]ush with [Q]wen14b' })

return M
