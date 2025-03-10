local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local nui_input = require 'nui.input'
local event = require('nui.utils.autocmd').event
local TerminalMultiplexer = require 'config.terminal_multiplexer'
local terminal_multiplexer = TerminalMultiplexer.new()
local terminal_name = 'terminal'

local choice_options_unix = {
  'gh_rerun_failed',
}

local choice_options_win = {
  'un',
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

vim.keymap.set({ 't', 'n' }, '<localleader>tt', function() terminal_multiplexer:toggle_float_terminal(terminal_name) end, { desc = '[T]erminal [T]oggle' })
vim.keymap.set('n', '<localleader>ts', Send_command_toggle_term, { desc = '[T]erminal [S]end command' })
return {}
