require 'config.terminal_util'

local floating_term_state = {
  buf = -1,
  win = -1,
  chan = 0,
}

function Create_floating_window(buf_intput)
  buf_intput = buf_intput or -1
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local row = math.floor((vim.o.columns - width))
  local col = math.floor((vim.o.lines - height))

  local buf = nil
  if buf_intput == -1 then
    buf = vim.api.nvim_create_buf(false, true)
  else
    buf = buf_intput
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

local toggle_floating_terminal = function()
  if vim.api.nvim_win_is_valid(floating_term_state.win) then
    vim.api.nvim_win_hide(floating_term_state.win)
    return
  end

  floating_term_state.buf, floating_term_state.win = Create_floating_window(floating_term_state.buf)
  if vim.bo[floating_term_state.buf].buftype ~= 'terminal' then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term 'powershell.exe'
    else
      vim.cmd.term()
    end

    floating_term_state.chan = vim.bo.channel
  end
  return floating_term_state.win
end

vim.keymap.set('n', '<localleader>tc', function()
  Send_command_toggle_term {
    is_float = true,
    toggle_term_func = toggle_floating_terminal,
    term_state = floating_term_state,
  }
end, { desc = '[T]erminal [C]ommand' })

vim.keymap.set({ 't', 'n' }, '<localleader>tt', toggle_floating_terminal, { desc = '[T]erminal [T]oggle' })
return {}
