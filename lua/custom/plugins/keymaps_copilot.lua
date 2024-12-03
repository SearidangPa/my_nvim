local map = vim.keymap.set

local function SuggestOneWord()
  vim.fn['copilot#Accept'] ''
  local bar = vim.fn['copilot#TextQueuedForInsertion']() or ''
  -- Trim leading/trailing spaces
  bar = bar:match '^%s*(.-)%s*$' or ''
  -- Match the first word, or use the entire `bar` if no space/dot is found
  local result = bar:match '^[^ .]+' or bar
  return string.format('%s ', result)
end

map('i', '<M-f>', SuggestOneWord, { expr = true, remap = false })

local function SuggestLine()
  vim.fn['copilot#Accept'] ''
  return vim.fn['copilot#TextQueuedForInsertion']()
end
if vim.fn.has 'win32' == 1 then
  map('i', '<M-l>', SuggestLine, { expr = true, remap = false })
else
  map('i', '<M-C-l>', SuggestLine, { expr = true, remap = false })
end

-- Function to accept a specified number of words
local function AcceptWords(num_words)
  vim.fn['copilot#Accept'] ''
  local bar = vim.fn['copilot#TextQueuedForInsertion']() or ''
  -- Trim leading/trailing spaces
  bar = bar:match '^%s*(.-)%s*$' or ''
  local words = {}
  for word in bar:gmatch '%S+' do
    table.insert(words, word)
    if #words == num_words then
      break
    end
  end
  -- Return the joined words or the entire text if not enough words
  return table.concat(words, ' ')
end

-- Map keys dynamically for <C-S-%d>
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
  -- Accept the suggestion
  vim.fn['copilot#Accept'] ''
  -- Get the queued text for insertion
  local queuedText = vim.fn['copilot#TextQueuedForInsertion']() or ''
  -- Trim leading and trailing spaces
  queuedText = queuedText:match '^%s*(.-)%s*$' or ''
  -- Split the text into lines
  local lines = {}
  for line in queuedText:gmatch '[^\n]+' do
    table.insert(lines, line)
  end
  -- Extract the first `n` lines or all lines if `n` is greater than available
  local selectedLines = vim.list_slice(lines, 1, n or #lines)
  -- Remove leading spaces or tabs from all lines
  for i, line in ipairs(selectedLines) do
    selectedLines[i] = line:match '^%s*(.-)$' -- Trim leading spaces/tabs
  end
  -- Concatenate lines with `\n`
  return table.concat(selectedLines, '\n') .. '\n'
end

-- Dynamically map keys for <C-S-%d>
for i = 1, 9 do
  local key
  if vim.fn.has 'win32' == 1 then
    key = string.format('<M-S-%d>', i)
  else
    key = string.format('<C-S-%d>', i)
  end
  map('i', key, function()
    return SuggestLines(i) -- Accept `i` lines dynamically based on the key
  end, { expr = true, remap = false })
end
return {}
