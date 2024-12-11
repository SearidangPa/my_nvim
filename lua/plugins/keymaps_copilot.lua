local map = vim.keymap.set
map('i', '<M-y>', function()
  return vim.fn['copilot#AcceptLine'] ''
end, { expr = true, remap = false })

map('i', '<M-f>', function()
  return vim.fn['copilot#AcceptWord'] ''
end, { expr = true, remap = false })

-- enable accept suggestion even when lsp menu is open
local function acceptSuggestion()
  vim.fn['copilot#Accept'] ''
  return vim.fn['copilot#TextQueuedForInsertion']()
end
if vim.fn.has 'win32' == 1 then
  map('i', '<M-l>', acceptSuggestion, { expr = true, remap = false })
else
  map('i', '<M-C-l>', acceptSuggestion, { expr = true, remap = false })
end

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
