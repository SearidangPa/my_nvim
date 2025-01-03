return {
  {
    'saghen/blink.cmp',
    dependencies = {
      'rafamadriz/friendly-snippets',
      { 'L3MON4D3/LuaSnip', version = 'v2.*' },
    },
    version = '*',
    opts = {
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono',
      },
      signature = { enabled = true },

      sources = {
        default = { 'lsp', 'path', 'luasnip', 'buffer' },
      },

      snippets = {
        expand = function(snippet)
          require('luasnip').lsp_expand(snippet)
        end,
        active = function(filter)
          if filter and filter.direction then
            return require('luasnip').jumpable(filter.direction)
          end
          return require('luasnip').in_snippet()
        end,
        jump = function(direction)
          require('luasnip').jump(direction)
        end,
      },

      keymap = {
        preset = 'default',
        ['<A-1>'] = {
          function(cmp)
            cmp.accept { index = 1 }
          end,
        },
        ['<A-2>'] = {
          function(cmp)
            cmp.accept { index = 2 }
          end,
        },
        ['<A-3>'] = {
          function(cmp)
            cmp.accept { index = 3 }
          end,
        },
        ['<A-4>'] = {
          function(cmp)
            cmp.accept { index = 4 }
          end,
        },
        ['<A-5>'] = {
          function(cmp)
            cmp.accept { index = 5 }
          end,
        },
        ['<A-6>'] = {
          function(cmp)
            cmp.accept { index = 6 }
          end,
        },
        ['<A-7>'] = {
          function(cmp)
            cmp.accept { index = 7 }
          end,
        },
        ['<A-8>'] = {
          function(cmp)
            cmp.accept { index = 8 }
          end,
        },
        ['<A-9>'] = {
          function(cmp)
            cmp.accept { index = 9 }
          end,
        },
        ['<A-0>'] = {
          function(cmp)
            cmp.accept { index = 10 }
          end,
        },
      },
    },
  },
}
