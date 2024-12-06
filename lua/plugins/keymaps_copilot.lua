local map = vim.keymap.set

local function SuggestLine()
  vim.fn['copilot#Accept'] ''
  return vim.fn['copilot#TextQueuedForInsertion']()
end
if vim.fn.has 'win32' == 1 then
  map('i', '<M-l>', SuggestLine, { expr = true, remap = false })
else
  map('i', '<M-C-l>', SuggestLine, { expr = true, remap = false })
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

for i = 1, 9 do
  local key
  if vim.fn.has 'win32' == 1 then
    key = string.format('<M-%d>', i)
  else
    key = string.format('<M-C-%d>', i)
  end
  map('i', key, function()
    return AcceptWords(i)
  end, { expr = true, remap = false })
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
  local key
  if vim.fn.has 'win32' == 1 then
    key = string.format('<M-S-%d>', i)
  else
    key = string.format('<C-S-%d>', i)
  end
  map('i', key, function()
    return SuggestLines(i)
  end, { expr = true, remap = false })
end
return {}
