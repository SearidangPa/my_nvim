require 'config.terminal_util'

local small_term_state = {
  buf = -1,
  win = -1,
  chan = 0,
}

local function small_terminal()
  vim.cmd.vnew()
  if vim.fn.has 'win32' == 1 then
    vim.cmd.term 'powershell.exe'
  else
    vim.cmd.term()
  end
  vim.cmd.wincmd 'J'

  local small_term_height = 12
  vim.api.nvim_win_set_height(0, small_term_height)
  small_term_state.buf = vim.api.nvim_get_current_buf()
  small_term_state.win = vim.api.nvim_get_current_win()
  small_term_state.chan = vim.bo.channel
  return small_term_state.win
end

local function toggle_small_terminal()
  if vim.api.nvim_win_is_valid(small_term_state.win) then
    vim.api.nvim_win_hide(small_term_state.win)
    return small_term_state.win
  end

  if not vim.api.nvim_buf_is_valid(small_term_state.buf) then
    return small_terminal()
  end

  small_term_state.win = vim.api.nvim_open_win(small_term_state.buf, true, {
    relative = 'editor',
    width = vim.o.columns,
    height = 12,
    row = vim.o.lines - 12,
    col = 0,
    style = 'minimal',
  })
  vim.cmd.wincmd 'J'

  small_term_state.chan = vim.bo.channel
  return small_term_state.win
end

vim.keymap.set('n', '<localleader>td', function()
  Send_command_toggle_term {
    is_float = false,
    toggle_term_func = toggle_small_terminal,
    term_state = small_term_state,
  }
end, { desc = '[T]oggle [S]mall terminal with command prompt' })

vim.keymap.set('n', '<localleader>ts', function()
  toggle_small_terminal()
end, { desc = 'Toggle small terminal' })
return {}
