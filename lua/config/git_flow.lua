local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local commit_msg = ''

local function git_add(on_success)
  vim.fn.jobstart('git add .', {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        on_success()
      else
        make_notify 'Git add all failed.'
      end
    end,
  })
end

local function git_commit(on_success)
  commit_msg = vim.fn.input 'Commit message: '
  if commit_msg == '' then
    make_notify 'Commit aborted: no message provided.'
    return
  end

  vim.fn.jobstart('git commit -m "' .. commit_msg .. '"', {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        on_success()
      else
        make_notify 'Git commit failed'
      end
    end,
  })
end

local function git_push()
  vim.fn.jobstart('git push', {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        make_notify(string.format(
          [[Git push successful!
          Commit: %s
          ]],
          commit_msg
        ))
      else
        make_notify 'Git push failed'
      end
    end,
  })
end

local function fugitive_git_workflow()
  git_add(function()
    git_commit(function()
      git_push()
    end)
  end)
end

vim.keymap.set('n', '<leader>gcp', fugitive_git_workflow, {
  noremap = true,
  silent = true,
  desc = 'Git workflow: add, commit, push',
})

return {}
