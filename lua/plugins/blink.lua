-- === keymap ===
local function generate_keymap()
  local keymap = {}
  keymap.preset = 'none' -- Explicit assignment to avoid conflicts

  for i = 1, 10 do
    local key = i == 10 and '<A-0>' or ('<A-' .. i .. '>')
    keymap[key] = {
      function(cmp)
        cmp.accept { index = i }
      end,
    }
  end

  keymap['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' }
  keymap['<C-y>'] = { 'select_and_accept' }
  keymap['<C-p>'] = { 'select_prev', 'fallback' }
  keymap['<C-n>'] = { 'select_next', 'fallback' }
  keymap['<C-b>'] = { 'scroll_documentation_up', 'fallback' }
  keymap['<C-f>'] = { 'scroll_documentation_down', 'fallback' }
  keymap['<C-e>'] = { 'hide' }

  return keymap
end

--- === snippets ===
local snippets = {
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
}

--- === cmdline ===
local cmdline = {
  keymap = {
    preset = 'cmdline',
  },
  completion = {
    menu = {
      auto_show = function(ctx)
        return vim.fn.getcmdtype() == ':'
      end,
    },
  },
}

--- === completion ===
local completion = {
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
  documentation = { auto_show = true, auto_show_delay_ms = 500 },
}

return {
  {
    'saghen/blink.cmp',
    dependencies = {
      { 'L3MON4D3/LuaSnip', version = 'v2.*' },
    },
    version = '*',
    opts = {
      appearance = { use_nvim_cmp_as_default = true, nerd_font_variant = 'mono' },
      signature = { enabled = true },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      snippets = snippets,
      completion = completion,
      keymap = generate_keymap(),
      cmdline = cmdline,
    },
  },
}
