require 'config.util_job'
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local nui_input = require 'nui.input'
local event = require('nui.utils.autocmd').event

local height = math.floor(vim.o.lines * 0.25)
local row = math.floor((vim.o.lines - height) / 2)
local col = math.floor((vim.o.columns / 5))

local default_no_more_input = {
  'Done with what I set out to do',

  [[Man only likes to count his troubles; he doesn't calculate his joys. -- Fyodor Dostoevsky]],
  'Beauty will save the world. -- Fyodor Dostoevsky',
  'To live without hope is to cease to live.-- Fyodor Dostoevsky',
  'Taking a new step, uttering a new word, is what people fear most. -- Fyodor Dostoevsky',
  'Man is sometimes extraordinarily, passionately, in love with suffering. -- Fyodor Dostoevsky',
  'What is hell? I maintain that it is the suffering of being unable to love. -- Fyodor Dostoevsky',
  'The cleverest of all, in my opinion, is the man who calls himself a fool at least once a month. -- Fyodor Dostoevsky',
}

local item_options = {
  'Save progress',
  'Checkpoint',
  'Refinement',
}

local choice_options = vim.list_extend(item_options, default_no_more_input)
local commit_msg = ''

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

local commit_format_notification = [[Push successfully
Commit: %s]]

local function handle_choice(choice, perform_commit_func)
  if not choice then
    make_notify 'Commit aborted: no message selected.'
    return
  end

  commit_msg = choice

  if Contains(default_no_more_input, choice) then
    perform_commit_func(commit_msg)
    return
  end

  local nui_input_options = {
    prompt = '> ',
    default_value = string.format('%s: ', commit_msg),
    on_submit = function(value)
      commit_msg = value
      perform_commit_func(commit_msg)
    end,
  }

  local input = nui_input(popup_option, nui_input_options)
  input:mount()

  input:on(event.BufLeave, function() input:unmount() end)
end

local function select_commit_message_prompt(cb)
  local opts = {
    prompt = 'Select suggested commit message:',
    format_item = function(item) return item end,
  }

  vim.ui.select(choice_options, opts, function(choice) handle_choice(choice, cb) end)
end

-- === Git ===
local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

map('n', '<leader>gc', function()
  local commit_func = function(commit_msg, push_func)
    vim.schedule(function()
      vim.cmd 'Gwrite'
      vim.cmd('silent! G commit -m "' .. commit_msg .. '"')
      vim.cmd 'silent G push'
      make_notify(string.format(commit_format_notification, commit_msg))
    end)
  end
  select_commit_message_prompt(commit_func)
end, map_opt '[G]it [C]ommit and push')

-- === Async Git ===
local start_job = require('config.util_job').start_job
local async_make_job = require 'config.async_make_job'

local function git_add_all(on_success_cb)
  start_job {
    cmd = 'git add .',
    on_success_cb = on_success_cb,
    silent = true,
  }
end

local commit_format_notification = [[Push successfully
Commit: %s]]

local function git_push()
  start_job {
    cmd = 'git push',
    on_success_cb = function() make_notify(string.format(commit_format_notification, commit_msg)) end,
    silent = true,
  }
end

local function push_all()
  local cb = function(commit_msg)
    vim.cmd('silent! G commit -m "' .. commit_msg .. '"')
    git_push()
    async_make_job.make_lint()
    async_make_job.make_all()
    local terminals_test = require 'config.terminals_test'
    terminals_test.test_track()
  end
  git_add_all(function() select_commit_message_prompt(cb) end)
end

map('n', '<leader>gs', ':G<CR>', map_opt '[G]it [S]tatus')
map('n', '<leader>gw', ':Gwrite<CR>', map_opt '[G]it [W]rite')
map('n', '<leader>gp', push_all, map_opt '[G]it [C]ommit and push')
return {}
