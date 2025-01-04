local function generate_keymap()
  local keymap = {}
  keymap.preset = 'default' -- Explicit assignment to avoid conflicts

  for i = 1, 10 do
    local key = i == 10 and '<A-0>' or ('<A-' .. i .. '>')
    keymap[key] = {
      function(cmp)
        cmp.accept { index = i }
      end,
    }
  end

  return keymap
end

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

      completion = {
        list = {
          selection = function(ctx)
            return ctx.mode == 'cmdline' and 'auto_insert' or 'preselect'
          end,
        },
        menu = {
          draw = {
            columns = { { 'item_idx' }, { 'kind_icon', 'kind' }, { 'label', 'label_description', gap = 1 } },
            components = {
              item_idx = {
                text = function(ctx)
                  return ctx.idx == 10 and '0' or ctx.idx >= 10 and ' ' or tostring(ctx.idx)
                end,
              },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
        },
      },

      keymap = generate_keymap(),
    },
  },
}
