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

local state = {
  floating = {
    buf = -1,
    win = -1,
  }
}


local toggle_floating_terminal = function()
  if vim.api.nvim_win_is_valid(state.floating.win) then
    vim.api.nvim_win_hide(state.floating.win)
    return
  end

  state.floating.buf, state.floating.win = Create_floating_window(state.floating.buf)
  if vim.bo[state.floating.buf].buftype ~= "terminal" then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term('powershell.exe')
    else
      vim.cmd.term()
    end
  end
end

vim.api.nvim_create_user_command("Floaterminal", toggle_floating_terminal, {})
vim.keymap.set({ 't', 'n' }, '<leader>tt', toggle_floating_terminal,
  { noremap = true, silent = true, desc = 'Toggle floating terminal' })
