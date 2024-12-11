local map = vim.keymap.set
map('i', '<M-y>', function()
  return vim.fn['copilot#AcceptLine'] ''
end, { expr = true, remap = false })

map('i', '<M-f>', function()
  return vim.fn['copilot#AcceptWord'] ''
end, { expr = true, remap = false })

-- local function acceptSuggestion()
--   vim.fn['copilot#Accept'] ''
--   return vim.fn['copilot#TextQueuedForInsertion']()
-- end

-- map('i', '<Plug>(vimrc:copilot-dummy-map)', 'copilot#Accept("")', { expr = true, remap = false, desc = 'Accept suggestion' })

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
