local function lsp_references_to_quickfix(line, col)
  if not line or not col then
    print 'Line and column are required.'
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
    position = { line = line - 1, character = col - 1 },
    context = { includeDeclaration = false },
  }

  vim.lsp.buf_request(0, 'textDocument/references', params, function(err, result, _, _)
    if err or not result then
      print 'No references found or an error occurred.'
      return
    end

    local qflist = {}
    for _, ref in ipairs(result) do
      local uri = ref.uri or ref.targetUri
      if uri then
        local filename = vim.uri_to_fname(uri)
        if filename and not filename:match '_test%.go$' then
          local range = ref.range or ref.targetSelectionRange
          if range and range.start then
            local ref_lnum = range.start.line + 1
            local ref_col = range.start.character + 1
            table.insert(qflist, {
              filename = filename,
              lnum = ref_lnum,
              col = ref_col,
              text = filename .. ':' .. ref_lnum,
            })
          end
        end
      end
    end

    vim.fn.setqflist(qflist)
  end)
end

local function lsp_references_nearest_function()
  require 'config.util_find_func'
  local func_node = Nearest_func_node()
  assert(func_node, 'No function found')

  local func_identifier
  for child in func_node:iter_children() do
    if child:type() == 'identifier' or child:type() == 'name' then
      func_identifier = child
    end
  end

  local start_row, start_col = func_identifier:range()
  assert(start_row, 'start_row is nil')
  assert(start_col, 'start_col is nil')
  lsp_references_to_quickfix(start_row + 1, start_col + 1) -- Adjust from 0-indexed to 1-indexed positions.
end

vim.api.nvim_create_user_command('LspReferencesFunc', lsp_references_nearest_function, {})
local map = vim.keymap.set

local function toggle_quickfix()
  if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix == 1 then
    vim.cmd 'cclose'
  else
    vim.cmd 'copen'
  end
end

-- Quickfix navigation
map('n', '<leader>qn', ':cnext<CR>', { desc = 'Next Quickfix item' })
map('n', '<leader>qp', ':cprevious<CR>', { desc = 'Previous Quickfix item' })

-- Quickfix window controls
map('n', '<leader>qc', ':cclose<CR>', { desc = 'Close Quickfix window' })
map('n', '<leader>qo', ':copen<CR>', { desc = 'Open Quickfix window' })
map('n', '<leader>qt', toggle_quickfix, { desc = 'toggle diagnostic windows' })
map('n', '<leader>qf', vim.diagnostic.open_float, { desc = 'Open diagnostic [f]loat' })

--- Quickfix load
map('n', '<leader>ql', vim.diagnostic.setqflist, { desc = '[Q]uickfix [L]ist' })
map('n', '<leader>qr', lsp_references_nearest_function, { desc = 'Go to func references (excluding test files)' })
