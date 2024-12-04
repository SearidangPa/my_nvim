return {
  'L3MON4D3/LuaSnip',
  build = (function()
    return 'make install_jsregexp'
  end)(),

  config = function()
    local ls = require 'luasnip'
    local types = require 'luasnip.util.types'

    ls.config.setup {
      history = true,
      updateevents = 'TextChanged,TextChangedI',
      enable_autosnippets = true,

      ext_opts = {
        [types.choiceNode] = {
          active = {
            virt_text = { { '●', 'GruvboxOrange' } },
          },
        },
        [types.insertNode] = {
          active = {
            virt_text = { { '●', 'GruvboxBlue' } },
          },
        },
      },
    }

    local path_sep = package.config:sub(1, 1) -- Detects the path separator (e.g., '\' on Windows, '/' on Unix)
    local snippet_path = vim.fn.stdpath 'config' .. path_sep .. 'lua' .. path_sep .. 'custom' .. path_sep .. 'snippets'
    require('luasnip.loaders.from_lua').load { paths = { snippet_path } }

    vim.snippet.expand = ls.lsp_expand

    ---@diagnostic disable-next-line: duplicate-set-field
    vim.snippet.active = function(filter)
      filter = filter or {}
      filter.direction = filter.direction or 1

      if filter.direction == 1 then
        return ls.expand_or_jumpable()
      else
        return ls.jumpable(filter.direction)
      end
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    vim.snippet.jump = function(direction)
      if direction == 1 then
        if ls.expandable() then
          return ls.expand_or_jump()
        end
        return ls.jumpable(1) and ls.jump(1)
      end

      return ls.jumpable(-1) and ls.jump(-1)
    end

    vim.keymap.set({ 'i', 's' }, '<c-k>', function()
      return vim.snippet.active { direction = 1 } and vim.snippet.jump(1)
    end, { silent = true })

    vim.keymap.set({ 'i', 's' }, '<c-j>', function()
      return vim.snippet.active { direction = -1 } and vim.snippet.jump(-1)
    end, { silent = true })

    vim.keymap.set({ 'i', 's' }, '<C-]>', function()
      if ls.choice_active() then
        ls.change_choice(1)
      end
    end, { silent = true })
  end,
}
