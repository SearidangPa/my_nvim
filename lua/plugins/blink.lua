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
      { 'L3MON4D3/LuaSnip', version = 'v2.*' },
      { 'mikavilpas/blink-ripgrep.nvim' },
    },
    version = '*',
    opts = {
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono',
      },
      signature = { enabled = true },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'ripgrep' },
        providers = {
          ripgrep = {
            module = 'blink-ripgrep',
            name = 'Ripgrep',
            transform_items = function(_, items)
              for _, item in ipairs(items) do
                -- example: append a description to easily distinguish rg results
                item.kind_icon = 'rg'
              end
              return items
            end,
          },
        },
      },

      snippets = {
        preset = 'luasnip',
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
        menu = {
          draw = {
            columns = { { 'label' }, { 'kind_icon' }, { 'item_idx' } },
            components = {
              item_idx = {
                text = function(ctx)
                  return ctx.idx == 10 and '0' or ctx.idx >= 10 and ' ' or tostring(ctx.idx)
                end,
                highlight = 'BlinkCmpItemIdx',
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
