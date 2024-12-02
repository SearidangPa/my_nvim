local map = vim.keymap.set

local function SuggestOneWord()
  vim.fn['copilot#Accept'] ''
  local bar = vim.fn['copilot#TextQueuedForInsertion']() or ''
  -- Trim leading/trailing spaces
  bar = bar:match '^%s*(.-)%s*$' or ''
  -- Match the first word, or use the entire `bar` if no space/dot is found
  local result = bar:match '^[^ .]+' or bar
  return result
end

if vim.fn.has 'win32' == 1 then
  map('i', '<M-Right>', SuggestOneWord, { expr = true, remap = false })
else
  map('i', '<M-C-Right>', SuggestOneWord, { expr = true, remap = false })
end

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

local function SuggestFirstLine()
  -- Accept the suggestion
  vim.fn['copilot#Accept'] ''
  -- Get the queued text for insertion
  local queuedText = vim.fn['copilot#TextQueuedForInsertion']() or ''
  -- Trim leading and trailing spaces
  queuedText = queuedText:match '^%s*(.-)%s*$' or ''
  -- Extract the first line of the suggestion
  local firstLine = queuedText:match '^[^\n]*' or ''
  return firstLine
end

-- Dynamically map keys for <C-S-%d>
for i = 1, 9 do
  local key
  if vim.fn.has 'win32' == 1 then
    key = string.format('<M-%d>', i)
  else
    key = string.format('<M-C-%d>', i)
  end
  map('i', key, function()
    return SuggestFirstLine() -- Use the function to accept only the first line
  end, { expr = true, remap = false })
end

return {}
