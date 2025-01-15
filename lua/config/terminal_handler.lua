require 'config.terminal_float'

function Handle_choice(opts)
  local is_float = opts.is_float
  local choice = opts.choice
  local term_state = opts.term_state
  local toggle_term_func = opts.toggle_term_func

  local channel_id, buf
  local win = term_state.win
  if not vim.api.nvim_win_is_valid(win) then
    win = toggle_term_func()
  end

  channel_id = term_state.chan
  buf = term_state.buf

  if choice == '<Ctrl-C>' then
    vim.fn.chansend(channel_id, '\x03')
  else
    vim.fn.chansend(channel_id, string.format('%s\r\n', choice))
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_win_set_cursor(win, { line_count, 0 })

  if not is_float then
    Focus_above_small_terminal(term_state)
  end
end
