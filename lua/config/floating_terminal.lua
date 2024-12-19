local state = {
  floating = {
    buf = -1,
    win = -1,
  }
}


local toggle_floating_terminal = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating.buf, state.floating.win = Create_floating_window { buf = state.floating.buf }
    -- if vim.bo[state.floating.buf].buftype ~= "terminal" then
    --   vim.cmd.term()
    -- end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

vim.api.nvim_create_user_command("Floaterminal", toggle_floating_terminal, {})
vim.keymap.set({ 't', 'n' }, '<leader>tt', toggle_floating_terminal,
  { noremap = true, silent = true, desc = 'Toggle floating terminal' })




-- vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
-- if vim.fn.has 'win32' == 1 then
--   vim.keymap.set('n', '<leader>tt', '<cmd>term powershell.exe<CR>a', { desc = 'Open terminal' })
-- else
--   vim.keymap.set('n', '<leader>tt', '<cmd>term<CR>a', { desc = 'Open terminal' })
-- end
