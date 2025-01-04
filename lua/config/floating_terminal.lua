vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

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
  },
}

local toggle_floating_terminal = function()
  if vim.api.nvim_win_is_valid(state.floating.win) then
    vim.api.nvim_win_hide(state.floating.win)
    return
  end

  state.floating.buf, state.floating.win = Create_floating_window(state.floating.buf)
  if vim.bo[state.floating.buf].buftype ~= 'terminal' then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term 'powershell.exe'
    else
      vim.cmd.term()
    end

    vim.api.nvim_feedkeys('i', 'n', true)
  end
end

vim.api.nvim_create_user_command('Floaterminal', toggle_floating_terminal, {})
vim.keymap.set({ 't', 'n' }, '<leader>tt', toggle_floating_terminal, { noremap = true, silent = true, desc = '[T]oggle floating [t]erminal' })

local job_id = 0
local function small_terminal()
  vim.cmd.vnew()
  if vim.fn.has 'win32' == 1 then
    vim.cmd.term 'powershell.exe'
  else
    vim.cmd.term()
  end

  vim.cmd.wincmd 'J'
  vim.api.nvim_win_set_height(0, 15)
  vim.api.nvim_feedkeys('i', 'n', true)
  job_id = vim.bo.channel
  return job_id
end

vim.keymap.set('n', '<leader>st', small_terminal, { desc = '[S]mall [T]erminal' })

vim.keymap.set('n', '<leader>xst', function()
  vim.fn.chansend(job_id, 're;st\n')
end, { desc = 'Send re;st to terminal' })

return {}
