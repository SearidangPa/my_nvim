local finders = require 'telescope.finders'
local pickers = require 'telescope.pickers'
local conf = require('telescope.config').values
local themes = require 'telescope.themes'

local function lsp_references_filtered_test_files()
  vim.lsp.buf_request(0, 'textDocument/references', vim.lsp.util.make_position_params(), function(err, result, _, _)
    if err or not result then
      return
    end

    local filtered_results = {}
    for _, ref in ipairs(result) do
      local uri = ref.uri or ref.targetUri
      local filename = vim.uri_to_fname(uri)
      if not filename:match '_test%.go$' then
        table.insert(filtered_results, ref)
      end
    end

    local opts = themes.get_ivy {
      prompt_title = 'LSP References (excluding test files)',
      finder = finders.new_table {
        results = filtered_results,
        entry_maker = function(entry)
          local uri = entry.uri or entry.targetUri
          local filename = vim.uri_to_fname(uri)
          local range = entry.range or entry.targetSelectionRange
          local lnum = range.start.line + 1
          local col = range.start.character + 1
          return {
            value = entry,
            ordinal = filename,
            display = filename .. ':' .. lnum,
            filename = filename,
            lnum = lnum,
            col = col,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = conf.qflist_previewer {},
    }

    pickers.new(opts):find()
  end)
end
vim.keymap.set('n', '<leader>gr', lsp_references_filtered_test_files, { desc = 'Go to references (excluding test files)' })

local construct_args_glob_no_test_files = function(prompt)
  if not prompt or prompt == '' then
    return nil
  end
  local pieces = vim.split(prompt, '  ')
  local args = { 'rg' }

  if pieces[1] then
    table.insert(args, pieces[1])
  end
  table.insert(args, '--glob')
  table.insert(args, '!*test*')
  return args
end

vim.keymap.set('n', '<leader>gx', function()
  require 'config.telescope_multigrep'
  Live_search {
    args_constructor = construct_args_glob_no_test_files,
    prompt_title = 'grep (excluding test files)',
  }
end, { desc = 'Search [G]rep [X](excluding test files)' })

local builtin = require 'telescope.builtin'

vim.keymap.set('n', '<leader>sx', function()
  builtin.grep_string {
    additional_args = function(opts)
      return { '--glob', '!*test*' }
    end,
    prompt_title = 'find word (excluding test files)',
  }
end, { desc = '[S]earch current word e[x]cluding tests' })
