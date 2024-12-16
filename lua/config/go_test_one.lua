require 'config.find_test_line'
require 'config.floating_window'
local ns = vim.api.nvim_create_namespace 'live_tests'

local ts_utils = require 'nvim-treesitter.ts_utils'
local get_node_text = vim.treesitter.get_node_text

function GetEnclosingFunctionName()
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

vim.keymap.set('n', '<leader>fn', function()
  local startLine, func_name = GetEnclosingFunctionName()
  print(string.format('Enclosing function name: %s at line %d', func_name, startLine))
end, { desc = 'Print the enclosing function name' })
local attach_to_buffer = function(bufnr, command)
  local state = {
    bufnr = bufnr,
    tests = {},
  }

  local testsCurrBuf = Find_all_tests(bufnr)

  vim.api.nvim_buf_create_user_command(bufnr, 'GoTestDiag', function()
    vim.cmd.new()
    for _, test in pairs(state.tests) do
      if test.success == false then
        local currentBuf = vim.api.nvim_get_current_buf()
        local num_lines = vim.api.nvim_buf_line_count(currentBuf)
        vim.api.nvim_buf_set_lines(currentBuf, num_lines, num_lines, false, test.output)
      end
    end
  end, {})

  vim.api.nvim_buf_create_user_command(bufnr, 'GoTestLineDiag', function()
    local testLine, _ = GetEnclosingFunctionName()
    testLine = testLine - 1
    for _, test in pairs(state.tests) do
      if test.line == testLine then
        vim.cmd.new()
        vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), 0, -1, false, test.output)
      end
    end
  end, {})

  local make_key = function(entry)
    assert(entry.Package, 'Must have package name' .. vim.inspect(entry))
    if not entry.Test then
      return entry.Package
    end
    assert(entry.Test, 'Must have test name' .. vim.inspect(entry))
    return string.format('%s/%s', entry.Package, entry.Test)
  end

  local add_golang_test = function(entry)
    local testLine = testsCurrBuf[entry.Test]
    if not testLine then
      testLine = 0
    end

    state.tests[make_key(entry)] = {
      name = entry.Test,
      line = testLine - 1,
      output = {},
    }
  end

  local add_golang_output = function(entry)
    assert(state.tests, vim.inspect(state))
    table.insert(state.tests[make_key(entry)].output, vim.trim(entry.Output))
  end

  local mark_success = function(entry)
    local test = state.tests[make_key(entry)]
    if not test then
      return
    end
    test.success = entry.Action == 'pass'
  end

  local group = vim.api.nvim_create_augroup('teej-automagic', { clear = true })
  local ignored_actions = {
    pause = true,
    cont = true,
    start = true,
    skip = true,
  }
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*.go',
    callback = function()
      vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          if not data then
            return
          end

          for _, line in ipairs(data) do
            if line == '' then
              goto continue
            end
            local decoded = vim.json.decode(line)
            assert(decoded, 'Failed to decode: ' .. line)

            if ignored_actions[decoded.Action] then
              goto continue
            end

            if decoded.Action == 'run' then
              add_golang_test(decoded)
              goto continue
            end

            if decoded.Action == 'output' then
              if decoded.Test then
                add_golang_output(decoded)
              end
              goto continue
            end

            if decoded.Action == 'pass' or decoded.Action == 'fail' then
              mark_success(decoded)
              local test = state.tests[make_key(decoded)]
              if not test then
                print('Failed to find test: ' .. line)
                goto continue
              end

              if not test.success then
                goto continue
              end
              local current_time = os.date '%H:%M:%S'
              print('Current time:', current_time)
              local existing_extmarks = vim.api.nvim_buf_get_extmarks(state.bufnr, ns, { test.line, 0 }, { test.line, -1 }, {})
              if #existing_extmarks < 1 then
                vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, 0, {
                  virt_text = {
                    { string.format('%s %s', '✔', current_time) },
                  },
                })
              end

              goto continue
            end

            print('Failed to handle: ' .. line)
            ::continue::
          end
        end,

        on_exit = function()
          print 'Tests finished'
          local failed = {}
          for _, test in pairs(state.tests) do
            if not test.line or test.success then
              goto continue
            end

            table.insert(failed, {
              bufnr = bufnr,
              lnum = test.line,
              col = 0,
              severity = vim.diagnostic.severity.ERROR,
              source = 'go-test',
              message = 'Test Failed',
              user_data = {},
            })

            ::continue::
          end

          vim.diagnostic.set(ns, bufnr, failed, {})
        end,
      })
    end,
  })
end

vim.api.nvim_create_user_command('GoTestOnSave', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local testsInCurrBuf = Find_all_tests(bufnr)
  local concatTestName = ''
  for testName, _ in pairs(testsInCurrBuf) do
    concatTestName = concatTestName .. testName .. '|'
  end
  concatTestName = concatTestName:sub(1, -2) -- remove the last |
  local command = { 'go', 'test', './...', '-json', '-v', '-run', string.format('%s', concatTestName) }
  attach_to_buffer(bufnr, command)
end, {})

-- unattach the autocommand
vim.api.nvim_create_user_command('StopGoTestOnSave', function()
  vim.api.nvim_del_augroup_by_name 'teej-automagic'
  vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), ns, 0, -1)
  vim.diagnostic.reset()
end, {})

return {}
