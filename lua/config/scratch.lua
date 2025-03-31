local M = {}
local async = require 'plenary.async'
local Job = require 'plenary.job'

-- Function to get git diff asynchronously
local function get_git_diff(branch_name, callback)
  Job:new({
    command = 'git',
    args = { 'diff', branch_name },
    on_exit = function(j, return_val)
      if return_val == 0 then
        -- Schedule the callback to run in the main loop
        vim.schedule(function() callback(table.concat(j:result(), '\n')) end)
      else
        -- Schedule error notification to run in the main loop
        vim.schedule(function()
          vim.notify('Error getting git diff: ' .. table.concat(j:stderr_result(), '\n'), vim.log.levels.ERROR)
          callback ''
        end)
      end
    end,
  }):start()
end

-- Function to get current branch name
local function get_current_branch(callback)
  Job:new({
    command = 'git',
    args = { 'rev-parse', '--abbrev-ref', 'HEAD' },
    on_exit = function(j, return_val)
      if return_val == 0 then
        local branch = j:result()[1]
        vim.schedule(function() callback(branch) end)
      else
        vim.schedule(function()
          vim.notify('Error getting current branch: ' .. table.concat(j:stderr_result(), '\n'), vim.log.levels.ERROR)
          callback(nil)
        end)
      end
    end,
  }):start()
end

-- Function to check if there's an open PR for the current branch and get its title
local function get_open_pr_title(branch_name, callback)
  -- This requires the GitHub CLI to be installed (gh)
  Job:new({
    command = 'gh',
    args = { 'pr', 'view', '--json', 'title', '--jq', '.title' },
    on_exit = function(j, return_val)
      if return_val == 0 then
        local pr_title = j:result()[1]
        vim.schedule(function() callback(pr_title) end)
      else
        -- No open PR or other error
        vim.schedule(function() callback(nil) end)
      end
    end,
  }):start()
end

-- Main PR description generator function
M.pr_desc_prompt = function(branch_name)
  branch_name = branch_name or 'main'

  -- Get current branch if not specified
  get_current_branch(function(current_branch)
    if not current_branch then
      vim.notify('Could not determine current branch.', vim.log.levels.ERROR)
      return
    end

    -- Create new scratch buffer
    vim.cmd 'enew'
    vim.cmd 'setlocal buftype=nofile bufhidden=hide noswapfile'
    vim.cmd 'setlocal filetype=markdown'

    -- Set a loading message
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { 'Loading git diff data and checking for open PRs...' })

    -- Check for open PR title
    get_open_pr_title(current_branch, function(pr_title)
      if pr_title then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'Open PR found: ' .. pr_title })
      else
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'No open PR found for this branch.' })
      end
      -- Get diff asynchronously
      get_git_diff(branch_name, function(diff_input)
        if diff_input == '' then
          vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'No diff data available.' })
          return
        end

        local title_prompt = 'Take into consideration useful information from the PR Title: \n' .. pr_title .. '\n\n'
        local template = [[
        For the diff input above, please help me create a PR description as concise, terse, shorter as possible. 
        For each sections, I want at most 3 bullet points. Do not include code snippets or dependencies packages or references 
        to specific filenames. I want real, specific and meaningful details about the changes. Use dead simple words.
        Below is the pr template that I want you to fill out. Everything inside the angle brackets are my instructions to you. 
        ]] .. title_prompt .. [[
        ## What's the purpose of this change?
        ## Constraints and Mitigation
        <Each constraint should be followed with a sub-bullet point that contains a mitigation strategy. like this:
        <Constraints>
        ╰─ .. <Mitigation strategy>
        ## Flow Diagram
        <Mermaid diagram of how the program flow with relation to the changes.>
        ## Brief description of the changes
        ## Test Section
          <For each new test added. I want you to consider the test name, the test description, the setup and the expected outcome. 
          Explain in ascii flow diagram for the higher level flow of each test. 
          I want color highlight around the test name to be displayed in the github pr description. 
          I only want mermaid flow diagram and nothing else under each test name.>
        ]]

        -- Construct the full prompt
        local full_prompt = '```\n' .. diff_input .. '\n```\n\n' .. template
        -- Update the buffer with the prompt
        vim.schedule(function()
          vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(full_prompt, '\n'))
          vim.cmd [[normal! G]]
        end)
      end)
    end)
  end)
end

vim.api.nvim_create_user_command('NewPromptPrDesc', function(opts)
  local branch_name = opts.args
  if branch_name == '' then
    branch_name = 'main'
  end
  M.pr_desc_prompt(branch_name)
end, { nargs = '?' })

return M
