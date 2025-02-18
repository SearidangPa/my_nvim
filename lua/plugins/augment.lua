local map = vim.keymap.set
local map_opt = function(opts)
  local opts = vim.tbl_deep_extend('force', opts, { noremap = true, silent = true })
  return opts
end

local default_no_more_input = {
  '====================',
  'Explain this step by step',
}
local item_options = {
  'Double check everything along the way with print statement. Walk me through this task step by step',
}
local choice_options = vim.list_extend(item_options, default_no_more_input)

local height = math.floor(vim.o.lines * 0.25)
local row = math.floor((vim.o.lines - height) / 2)
local col = math.floor((vim.o.columns / 5))
local popup_option = {
  position = { row = row, col = col },
  size = { width = 100 },
  border = {
    style = 'rounded',
    text = {
      top = '[My Lovely Commit Message]',
      top_align = 'center',
    },
  },
  win_options = { winhighlight = 'Normal:Normal,FloatBorder:Normal' },
}

local function handle_choice(choice, on_success_cb)
  local mini_notify = require 'mini.notify'
  local make_notify = mini_notify.make_notify {}
  local nui_input = require 'nui.input'
  local event = require('nui.utils.autocmd').event
  if not choice then
    make_notify 'Commit aborted: no message selected.'
    return
  end

  if Contains(default_no_more_input, choice) then
    vim.cmd(string.format('Augment chat "%s"', choice))
    return
  end

  local nui_input_options = {
    prompt = '> ',
    default_value = string.format('%s: ', choice),
    on_submit = function(value)
      vim.cmd(string.format('Augment chat "%s"', value))
    end,
  }

  local input = nui_input(popup_option, nui_input_options)
  input:mount()

  input:on(event.BufLeave, function()
    input:unmount()
  end)
end

local function chat_with_custom_prompt()
  local opts = {
    prompt = 'Select suggested commit message:',
    format_item = function(item)
      return item
    end,
  }

  vim.ui.select(choice_options, opts, function(choice)
    handle_choice(choice)
  end)
end

return {
  'augmentcode/augment.vim',
  config = function()
    vim.g.augment_workspace_folders = {
      '~/Documents/windows',
      '~/Documents/drive',
      '~/Documents/drive-terminal',
      '~/.config/nvim',
    }
    vim.cmd [[:Augment disable]]
    vim.g.disable_tab_mapping = true

    local function map_accept_augment()
      map('i', '<C-l>', '<cmd>call augment#Accept()<CR>', { expr = false, desc = 'Accept Augment' })
    end

    local function activate_augment()
      vim.cmd [[Augment enable]]
      vim.cmd [[Copilot disable]]
      map_accept_augment()
    end

    map('n', '<localleader>ae', function()
      activate_augment()
      print 'Augment enabled'
    end, map_opt { desc = '[A]ugment [E]nable' })

    map('n', '<localleader>ad', function()
      vim.cmd [[Augment disable]]
      vim.cmd [[Copilot enable]]
      Map_copilot()
      print 'Augment disabled'
    end, map_opt { desc = '[A]ugment [D]isable' })

    map('n', '<localleader>at', ':Augment chat-toggle<CR>', map_opt { desc = '[C]hat [T]oggle' })

    map({ 'n', 'v' }, '<localleader>ac', function()
      activate_augment()
      vim.cmd [[Augment chat]]
    end, map_opt { desc = '[A]ugment [C]hat' })

    map({ 'n', 'v' }, '<localleader>cc', function()
      activate_augment()
      chat_with_custom_prompt()
    end, map_opt { desc = '[A]ugment [C]hat' })
  end,
}
