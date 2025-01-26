return {
  {
    'L3MON4D3/LuaSnip',
    version = 'v2.*',
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
              virt_text = { { '<-', 'GruvboxOrange' } },
            },
            unvisited = {
              virt_text = { { '○', 'GruvboxOrange' } },
            },
          },
        },
      }

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
      require 'config.go_snip'
    end,
  },
}
