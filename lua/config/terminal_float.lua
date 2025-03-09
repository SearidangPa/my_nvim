require 'config.terminal_util'

local floating_term_state = {
  buf = -1,
  win = -1,
  chan = 0,
  footer_buf = -1,
  footer_win = -1,
}

local function create_float_window(floating_term_state, term_name)
  local buf_input = floating_term_state.buf or -1
  local width = math.floor(vim.o.columns)
  local height = math.floor(vim.o.lines)
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
    height = height - 2,
    row = row,
    col = col,
    style = 'minimal',
    border = 'none',
  })

  local footer_buf = vim.api.nvim_create_buf(false, true)
  local padding = string.rep(' ', width - #term_name - 1)
  local footer_text = padding .. term_name
  vim.api.nvim_buf_set_lines(footer_buf, 0, -1, false, { footer_text })
  vim.api.nvim_buf_add_highlight(footer_buf, -1, 'Title', 0, 0, -1)

  vim.api.nvim_buf_add_highlight(footer_buf, -1, 'TestNameUnderlined', 0, #padding, -1)

  vim.api.nvim_win_call(win, function()
    vim.cmd 'normal! G'
  end)

  local footer_win = vim.api.nvim_open_win(footer_buf, false, {
    relative = 'win',
    width = width,
    height = 1,
    row = height - 1,
    col = 0,
    style = 'minimal',
    border = 'none',
  })

  floating_term_state.buf = buf
  floating_term_state.win = win
  floating_term_state.footer_buf = footer_buf
  floating_term_state.footer_win = footer_win
end

local toggle_floating_terminal = function()
  if vim.api.nvim_win_is_valid(floating_term_state.win) then
    vim.api.nvim_win_hide(floating_term_state.win)
    vim.api.nvim_win_hide(floating_term_state.footer_win)
    return
  end

  create_float_window(floating_term_state, 'Terminal')
  if vim.bo[floating_term_state.buf].buftype ~= 'terminal' then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term 'powershell.exe'
    else
      vim.cmd.term()
    end

    floating_term_state.chan = vim.bo.channel
  end

  vim.api.nvim_buf_set_keymap(floating_term_state.buf, 'n', 'q', '<cmd>q<CR>', { noremap = true, silent = true, desc = 'Previous test terminal' })
end

vim.keymap.set('n', '<localleader>ts', function()
  Send_command_toggle_term {
    is_float = true,
    toggle_term_func = toggle_floating_terminal,
    term_state = floating_term_state,
  }
end, { desc = '[T]erminal [S]end command' })

vim.keymap.set({ 't', 'n' }, '<localleader>tt', toggle_floating_terminal, { desc = '[T]erminal [T]oggle' })
return {}
