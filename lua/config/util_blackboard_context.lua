local function make_func_line(data)
  if not data.func_name or data.func_name == '' then
    return ''
  end
  return '❯ ' .. data.func_name
end

local function get_virtual_lines_no_func_lines(filename, last_seen_filename)
  if filename == last_seen_filename then
    return nil
  end
  return { { { '', '' } }, { { filename, 'FileHighlight' } } }
end

---@param options blackboard.Options
local function get_virtual_lines(filename, funcLine, last_seen_filename, last_seen_func, options)
  if not options.show_nearest_func or funcLine == '' then
    return get_virtual_lines_no_func_lines(filename, last_seen_filename)
  end
  if filename ~= last_seen_filename then
    return { { { '', '' } }, { { filename, 'FileHighlight' } }, { { funcLine, '@function' } } }
  end
  if funcLine ~= last_seen_func then
    return { { { '', '' } }, { { funcLine, '@function' } } }
  end
  return nil
end

---@param blackboard_state blackboard.State
---@param options blackboard.Options
function Add_virtual_lines(parsedMarks, blackboard_state, options)
  local ns_blackboard = vim.api.nvim_create_namespace 'blackboard_extmarks'
  local last_seen_filename = ''
  local last_seen_func = ''

  for lineNum, data in pairs(parsedMarks.virtualLines) do
    local filename = data.filename or ''
    local funcLine = make_func_line(data)
    local extmarkLine = lineNum - 1

    if extmarkLine == 1 then
      vim.api.nvim_buf_set_extmark(blackboard_state.blackboard_buf, ns_blackboard, 0, 0, {
        virt_lines = { { { filename, 'FileHighlight' } } },
        virt_lines_above = true,
        hl_mode = 'combine',
        priority = 10,
      })
    elseif extmarkLine > 1 then
      local virt_lines = get_virtual_lines(filename, funcLine, last_seen_filename, last_seen_func, options)
      if virt_lines then
        vim.api.nvim_buf_set_extmark(blackboard_state.blackboard_buf, ns_blackboard, extmarkLine, 0, {
          virt_lines = virt_lines,
          virt_lines_above = true,
          hl_mode = 'combine',
          priority = 10,
        })
      end
    end

    last_seen_filename = filename
    last_seen_func = funcLine
  end
end
