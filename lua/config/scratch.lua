local M = {}
local async = require 'plenary.async'
local Job = require 'plenary.job'

-- Function to get git diff asynchronously
local function get_git_diff(branch_name, callback)
  Job:new({
    command = 'git',
    args = { 'diff', branch_name, '--', ':!docs/*', ':!.github', ':!docs' },
    on_exit = function(j, return_val)
      if return_val == 0 then
        callback(table.concat(j:result(), '\n'))
      else
        vim.notify('Error getting git diff: ' .. table.concat(j:stderr_result(), '\n'), vim.log.levels.ERROR)
        callback ''
      end
    end,
  }):start()
end

-- Main PR description generator function
M.ai_pr_desc = function(branch_name)
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
  # Brief description from AI and me:
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
    local full_prompt = diff_input .. '\n' .. task_desc .. '\n' .. template .. '\n' .. task_context .. test_section_prompt .. flow_section_prompt_ascii

    -- Update the buffer with the prompt
    vim.schedule(function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(full_prompt, '\n'))
      -- Move cursor to the beginning of the buffer
      vim.cmd 'normal! gg'
      vim.notify('PR description template generated!', vim.log.levels.INFO)
    end)
  end)
end

-- Public function to create new PR description buffer
M.new_prompt_pr_desc = function(branch_name) M.ai_pr_desc(branch_name) end

return M
