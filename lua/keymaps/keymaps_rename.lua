local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

local function renameAndCapitalize()
  local current_word = vim.fn.expand '<cword>'
  local capitalized_word = current_word:sub(1, 1):upper() .. current_word:sub(2)
  vim.lsp.buf.rename(capitalized_word)
end

local function renameAndLowercase()
  local current_word = vim.fn.expand '<cword>'
  local lowercase_word = current_word:sub(1, 1):lower() .. current_word:sub(2)
  vim.lsp.buf.rename(lowercase_word)
end

local function substitue_visual_select()
  vim.cmd 'normal! y'
  local selected_text = vim.fn.escape(vim.fn.getreg '"', '/\\')
  selected_text = vim.trim(selected_text)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(':%s/' .. selected_text .. '//gc<Left><Left><Left>', true, true, true), 'n', false)
end

map('n', '<localleader>rc', renameAndCapitalize, map_opt '[R]ename and [C]apitalize first character')
map('n', '<localleader>rl', renameAndLowercase, map_opt '[R]ename and [L]owercase first character')
map('n', '<localleader>rs', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/g<Left><Left>]], map_opt 'Rename and capitalize current word')
map('v', '<leader>r', substitue_visual_select, { desc = 'Substitute the visual selection' })
