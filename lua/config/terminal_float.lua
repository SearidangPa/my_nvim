local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local nui_input = require 'nui.input'
local event = require('nui.utils.autocmd').event
local terminal_multiplexer = require('terminal-multiplexer').new()
local terminal_name = 'terminal'
M = {}
M.float_terminal_state = nil

local choice_options_unix = {
  'gh_rerun_failed',
  'start_ollama',
}

local choice_options_win = {
  'dr;m;rds',
  'tu',
  'GitBash -c "make -j lint"',
}

local function Send_command_toggle_term()
  local ui_select_opts = {
    prompt = 'Select command to send to terminal',
    format_item = function(item) return item end,
  }
  local choice_options
  if vim.fn.has 'win32' == 1 then
    choice_options = vim.deepcopy(choice_options_win)
  else
    choice_options = vim.deepcopy(choice_options_unix)
  end
  table.insert(choice_options, #choice_options + 1, '')

  terminal_multiplexer:toggle_float_terminal(terminal_name)
  local float_terminal_state = terminal_multiplexer:toggle_float_terminal(terminal_name)
  assert(float_terminal_state, 'Failed to toggle float terminal')

  vim.ui.select(choice_options, ui_select_opts, function(choice)
    if not choice then
      make_notify 'No choice selected'
      return
    end
    vim.fn.chansend(float_terminal_state.chan, string.format('%s\r', choice))
    terminal_multiplexer:toggle_float_terminal(terminal_name)
  end)
end

local function toggle_float_terminal_with_bind()
  M.float_terminal_state = terminal_multiplexer:toggle_float_terminal(terminal_name)
  assert(M.float_terminal_state, 'Failed to toggle float terminal')

  local close_term = function()
    if vim.api.nvim_win_is_valid(M.float_terminal_state.footer_win) then
      vim.api.nvim_win_hide(M.float_terminal_state.footer_win)
    end
    if vim.api.nvim_win_is_valid(M.float_terminal_state.win) then
      vim.api.nvim_win_hide(M.float_terminal_state.win)
    end
  end
  vim.keymap.set('n', 'q', close_term, { buffer = M.float_terminal_state.buf })
end

vim.keymap.set({ 't', 'n' }, '<localleader>tt', toggle_float_terminal_with_bind, { desc = '[T]erminal [T]oggle' })
vim.keymap.set('n', '<localleader>ts', Send_command_toggle_term, { desc = '[T]erminal [S]end command' })

return M
