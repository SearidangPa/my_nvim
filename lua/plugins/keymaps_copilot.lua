local map = vim.keymap.set
map('i', '<M-y>', function()
  local accept = vim.fn['copilot#AcceptLine']
  local res = accept(vim.api.nvim_replace_termcodes('<M-C-Right>', true, true, false))
  res = res .. '\n'
  vim.api.nvim_feedkeys(res, 'n', false)
end, { expr = true, remap = false, silent = true })

map('i', '<M-f>', function()
  return vim.fn['copilot#AcceptWord'] ''
end, { expr = true, remap = false })

local function SuggestLines(n)
  vim.fn['copilot#Accept'] ''
  local queuedText = vim.fn['copilot#TextQueuedForInsertion']() or ''
  queuedText = queuedText:match '^%s*(.-)%s*$' or ''
  local lines = {}
  for line in queuedText:gmatch '[^\n]+' do
    table.insert(lines, line)
  end
  local selectedLines = vim.list_slice(lines, 1, n or #lines)
  for i, line in ipairs(selectedLines) do
    selectedLines[i] = line:match '^%s*(.-)$' -- Trim leading spaces/tabs
  end
  return table.concat(selectedLines, '\n') .. '\n'
end

for i = 1, 9 do
  local key = string.format('<M-%d>', i)
  map('i', key, function()
    return SuggestLines(i)
  end, { expr = true, remap = false })
end

return {}
