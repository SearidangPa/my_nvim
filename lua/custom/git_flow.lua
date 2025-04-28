require 'config.util_job'

local height = math.floor(vim.o.lines * 0.25)
local row = math.floor((vim.o.lines - height) / 2)
local col = math.floor((vim.o.columns / 5))

local default_no_more_input = {
  'Pushing to remote',
  'Done with what I set out to do',
}

local item_options = {
  'Save progress:',
  'Debugging',
  'Fix:',
  'Checkpoint:',
  'Beautifully crafted:',
  'Refinement:',
}

local function copy_list(list)
  local new_list = {}
  for i, v in ipairs(list) do
    new_list[i] = v
  end
  return new_list
end

local choice_options = vim.list_extend(copy_list(default_no_more_input), item_options)
local commit_msg = ''

local function handle_choice(choice, perform_commit_func)
  if not choice then
    vim.notify('Commit aborted: no message selected.', vim.log.levels.WARN)
    return
  end

  commit_msg = choice

  local util_contains = require 'config.util_contains'
  if util_contains.contains(default_no_more_input, choice) then
    perform_commit_func(choice)
    return
  end

  local opts = {
    prompt = 'Commit message:',
    default = string.format('%s ', commit_msg),
  }
  require 'snacks.input'
  Snacks.input.input(opts, function(value)
    commit_msg = value
    if not value then
      vim.print 'Commit aborted: no message selected.'
      return
    end
    perform_commit_func(commit_msg)
  end)
end

local function select_commit_message_prompt(cb)
  local opts = {
    prompt = 'Select suggested commit message:',
    format_item = function(item) return item end,
  }

  vim.ui.select(choice_options, opts, function(choice) handle_choice(choice, cb) end)
end

local function git_add_all(on_success_cb)
  require('config.util_job').start_job {
    cmd = 'git add .',
    on_success_cb = on_success_cb,
    silent = true,
    ns = vim.api.nvim_create_namespace 'git_add',
  }
end

local commit_format_notification = [[Push successfully
Commit: %s]]

local function async_git_push()
  local fidget = require 'fidget'
  local fidget_handle = fidget.progress.handle.create {
    title = 'Git Push',
    lsp_client = {
      name = 'git push',
    },
  }
  require('config.util_job').start_job {
    cmd = 'git push',
    on_success_cb = function()
      local make_notify = require('mini.notify').make_notify {}
      make_notify(string.format(commit_format_notification, commit_msg))
    end,
    silent = true,
    ns = vim.api.nvim_create_namespace 'git_push',
    fidget_handle = fidget_handle,
  }
end

local function async_push_all()
  local on_success_cb = function(commit_msg)
    vim.cmd('silent! G commit -m "' .. commit_msg .. '"')
    if vim.bo.filetype == 'go' then
      local async_job = require 'config.async_job'
      async_job.make_lint()
      async_job.make_all()
    end
    async_git_push()
  end
  git_add_all(function() select_commit_message_prompt(on_success_cb) end)
end

local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end
map('n', '<leader>pa', async_push_all, map_opt '[P]ush [A]ll')
map('n', '<leader>pc', function()
  local commit_func_push = function(commit_msg)
    vim.schedule(function()
      vim.cmd 'Gwrite'
      vim.cmd('silent! G commit -m "' .. commit_msg .. '"')
      vim.cmd 'silent G push'
      local make_notify = require('mini.notify').make_notify {}
      make_notify(string.format(commit_format_notification, commit_msg))
    end)
  end
  select_commit_message_prompt(commit_func_push)
end, map_opt '[P]ush [C]ommit with fugitive')

return {}
