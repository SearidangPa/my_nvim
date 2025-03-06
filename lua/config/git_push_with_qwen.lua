local M = {}

local floating_term_state = {
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
  if vim.api.nvim_win_is_valid(floating_term_state.win) then
    vim.api.nvim_win_hide(floating_term_state.win)
    return
  end

  floating_term_state.buf, floating_term_state.win = create_qwen_floating_window(floating_term_state.buf)
  if vim.bo[floating_term_state.buf].buftype ~= 'terminal' then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term 'powershell.exe'
    else
      vim.cmd.term()
    end

    floating_term_state.chan = vim.bo.channel
  end
end

local push_all_with_qwen = function()
  toggle_qwen_floating_terminal()
  toggle_qwen_floating_terminal()
  local command_str = 'git add . && pg'
  vim.api.nvim_chan_send(floating_term_state.chan, command_str .. '\n')
  vim.api.nvim_buf_attach(floating_term_state.buf, false, {
    on_lines = function(_, buf, _, first_line, last_line)
      local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)
      for _, line in ipairs(lines) do
        print(line)
      end
    end,
  })
end

vim.api.nvim_create_user_command('GitPushWithQwen', push_all_with_qwen, {})
vim.api.nvim_create_user_command('QwenTermToggle', toggle_qwen_floating_terminal, {})
vim.keymap.set('n', '<leader>gp', ':GitPushWithQwen<CR>', { desc = '[Git] [P]ush with Qwen' })

return M
