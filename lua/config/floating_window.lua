local state = {
  floating = {
    buf = -1,
    win = -1,
  }
}


function Create_floating_window()
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local row = math.floor((vim.o.columns - width))
  local col = math.floor((vim.o.lines - height))

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  return { buf = buf, win = win }
end

local toggle_floating_terminal = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = Create_floating_window()
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

vim.api.nvim_create_user_command("Floaterminal", toggle_floating_terminal, {})
