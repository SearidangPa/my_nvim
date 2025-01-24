local ts_utils = require 'nvim-treesitter.ts_utils'
local get_node_text = vim.treesitter.get_node_text

local mini_notify = require 'mini_notify'
local make_notify = mini_notify.make_notify {}

function Get_enclosing_fn_info()
  local node = ts_utils.get_node_at_cursor()
  while node do
    if node:type() ~= 'function_declaration' then
      node = node:parent() -- Traverse up the node tree to find a function node
      goto continue
    end

    local func_name_node = node:child(1)
    if func_name_node then
      local func_name = get_node_text(func_name_node, 0)
      local startLine, _, _ = node:start()
      return startLine + 1, func_name -- +1 to convert 0-based to 1-based lua indexing system
    end
    ::continue::
  end

  return nil
end

function Get_enclosing_test()
  local _, testName = Get_enclosing_fn_info()
  if not testName then
    print 'Not in a function'
    return nil
  end
  if not string.match(testName, 'Test_') then
    print(string.format('Not in a test function: %s', testName))
    return nil
  end
  return testName
end

function Clean_up_prev_job(job_id)
  if job_id ~= -1 then
    make_notify(string.format('Stopping job: %d', job_id))
    vim.fn.jobstop(job_id)
    vim.diagnostic.reset()
  end
end
