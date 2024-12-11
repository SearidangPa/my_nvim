local map = vim.keymap.set

local function acceptSuggestion()
  vim.fn['copilot#Accept'] ''
  return vim.fn['copilot#TextQueuedForInsertion']()
end
if vim.fn.has 'win32' == 1 then
  map('i', '<M-l>', acceptSuggestion, { expr = true, remap = false })
else
  map('i', '<M-C-l>', acceptSuggestion, { expr = true, remap = false })
end

local function AcceptWords(num_words)
  vim.fn['copilot#Accept'] ''
  local bar = vim.fn['copilot#TextQueuedForInsertion']() or ''
  bar = bar:match '^%s*(.-)%s*$' or ''
  local words = {}
  for word in bar:gmatch '%S+' do
    table.insert(words, string.format('%s ', word))
    if #words == num_words then
      break
    end
  end
  return table.concat(words, ' ')
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
  local key = string.format('<M-C-%d>', i)
  map('i', key, function()
    return AcceptWords(i)
  end, { expr = true, remap = false })
end

local key = string.format('<M-f>', 1)
map('i', key, function()
  return SuggestLines(1)
end, { expr = true, remap = false })

key = string.format('<M-s>', 2)
map('i', key, function()
  return SuggestLines(2)
end, { expr = true, remap = false })

return {}
