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
map('i', '<C-S-Right>', SuggestOneWord, { expr = true, remap = false })

local function SuggestLine()
  vim.fn['copilot#Accept'] ''
  return vim.fn['copilot#TextQueuedForInsertion']()
end
map('i', '<C-S-CR>', SuggestLine, { expr = true, remap = false })

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
  local key = string.format('<C-S-%d>', i)
  map('i', key, function()
    return AcceptWords(i)
  end, { expr = true, remap = false })
end

return {}
