local M = {}
local async = require 'plenary.async'
local Job = require 'plenary.job'

-- Function to get git diff asynchronously
--
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

-- Main PR description generator function
M.pr_desc_prompt = function(branch_name)
  branch_name = branch_name or 'main'

  local test_section_prompt =
    '* In the test section, I want a couple bullet points of brief description of the changes. Then, I want to have a brief description of any new tests. I want you to include the test name, the test description, and the expected outcome.'

  local task_desc =
    'For the diff input above, please help me create a PR description as concise, terse, shorter as possible. give me a markdown file that i can copy'

  local task_context = [[
  * For each sections, I want at most 3 bullet points. Do not include code snippets or dependencies packages or references to specific filenames. I want real, specific and meaningful details about the changes. Do not include empty words. Make this sound important and impactful. Use dead simple words.
  ]]

  local flow_section_prompt_ascii = [[
  * Finally at the end, in the Flow section, you should supplement your description with a simple ascii art illustrating the flow between components. I want boxes drown around the components. I want it inside a triple backtick block with proper escaping.
  ]]

  local pr_desc_constraints = [[
  * Each constraint should be followed with a sub-bullet point that contains a mitigation strategy. 
  ]]

  local template = [[
  Below is the pr template that I want you to fill out. 
  ## What's the purpose of this change?
  ## Constraints and Mitigation
  ## Brief description of the changes
  ## Test Section
  ## Flow 
  ]]

  -- Create new scratch buffer
  vim.cmd 'enew'
  vim.cmd 'setlocal buftype=nofile bufhidden=hide noswapfile'
  vim.cmd 'setlocal filetype=markdown'

  -- Set a loading message
  vim.api.nvim_buf_set_lines(0, 0, 0, false, { 'Loading git diff data...' })

  -- Get diff asynchronously
  get_git_diff(branch_name, function(diff_input)
    if diff_input == '' then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'No diff data available.' })
      return
    end

    -- Construct the full prompt
    local full_prompt = '```\n'
      .. diff_input
      .. '\n```\n\n'
      .. task_desc
      .. '\n'
      .. template
      .. '\n'
      .. task_context
      .. test_section_prompt
      .. flow_section_prompt_ascii

    -- Update the buffer with the prompt
    vim.schedule(function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(full_prompt, '\n'))
      vim.cmd [[normal! G]]
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
