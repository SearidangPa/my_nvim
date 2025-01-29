local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local make_entry = require 'telescope.make_entry'
local conf = require('telescope.config').values
local themes = require 'telescope.themes'

local M = {}

local construct_args_multigrep = function(prompt)
  if not prompt or prompt == '' then
    return nil
  end
  local pieces = vim.split(prompt, '  ')
  local args = { 'rg' }

  if pieces[1] then
    table.insert(args, '-e')
    table.insert(args, pieces[1])
  end

  if pieces[2] then
    table.insert(args, '-g')
    table.insert(args, pieces[2])
  end
  return args
end

local construct_args_no_regex = function(prompt)
  if not prompt or prompt == '' then
    return nil
  end
  local pieces = vim.split(prompt, '  ')
  local args = { 'rg' }

  if pieces[1] then
    table.insert(args, '-F')
    table.insert(args, pieces[1])
  end
  return args
end

local live_search = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()
  opts = vim.tbl_deep_extend('force', themes.get_ivy(), opts)
  assert(opts.args_constructor, 'You need to pass an args_constructor')
  assert(opts.prompt_title, 'You need to pass a prompt_title')

  local finder = finders.new_async_job {
    command_generator = function(prompt)
      local args = opts.args_constructor(prompt)
      if not args then
        return nil
      end
      ---@diagnostic disable-next-line: deprecated
      return vim.tbl_flatten {
        args,
        {
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case',
        },
      }
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }

  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = opts.prompt_title,
      finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = require('telescope.sorters').empty(),
    })
    :find()
end

M.setup = function()
  vim.keymap.set('n', '<leader>sm', function()
    live_search {
      args_constructor = construct_args_multigrep,
      prompt_title = 'multi grep',
    }
  end, { desc = '[S]earch [M]ulti grep' })

  vim.keymap.set('n', '<leader>sF', function()
    live_search {
      args_constructor = construct_args_no_regex,
      prompt_title = 'no regex',
    }
  end, { desc = '[S]earch [N]o regex' })

  vim.keymap.set('n', '<localleader>sm', function()
    live_search {
      args_constructor = construct_args_multigrep,
      prompt_title = 'multi grep',
      cwd = vim.fs.joinpath(tostring(vim.fn.stdpath 'data'), 'lazy'),
    }
  end, { desc = '[S]earch [M]ulti grep in plugins' })
end

local telescope = require 'telescope'
local finders = require 'telescope.finders'
local pickers = require 'telescope.pickers'
local conf = require('telescope.config').values

local function lsp_references_filtered()
  vim.lsp.buf_request(0, 'textDocument/references', vim.lsp.util.make_position_params(), function(err, result, ctx, _)
    if err or not result then
      return
    end

    -- Filter out test files
    local filtered_results = {}
    for _, ref in ipairs(result) do
      local uri = ref.uri or ref.targetUri
      local filename = vim.uri_to_fname(uri)
      if not filename:match '_test%.go$' then
        table.insert(filtered_results, ref)
      end
    end

    -- Display filtered references using Telescope
    pickers
      .new({}, {
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
      })
      :find()
  end)
end

vim.keymap.set('n', 'gx', lsp_references_filtered, { desc = 'Go to references (excluding test files)' })
return M
