local function generate_keymap()
  local keymap = {}
  keymap.preset = 'none' -- Explicit assignment to avoid conflicts

  keymap['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' }
  keymap['<C-y>'] = { 'select_and_accept' }
  keymap['<C-p>'] = { 'select_prev', 'fallback' }
  keymap['<C-n>'] = { 'select_next', 'fallback' }
  keymap['<C-b>'] = { 'scroll_documentation_up', 'fallback' }
  keymap['<C-f>'] = { 'scroll_documentation_down', 'fallback' }
  keymap['<C-e>'] = { 'hide' }

  keymap['<C-1>'] = { function(cmp) cmp.accept { index = 1 } end }
  keymap['<C-2>'] = { function(cmp) cmp.accept { index = 2 } end }
  keymap['<C-3>'] = { function(cmp) cmp.accept { index = 3 } end }
  keymap['<C-4>'] = { function(cmp) cmp.accept { index = 4 } end }
  keymap['<C-5>'] = { function(cmp) cmp.accept { index = 5 } end }
  keymap['<C-6>'] = { function(cmp) cmp.accept { index = 6 } end }
  keymap['<C-7>'] = { function(cmp) cmp.accept { index = 7 } end }
  keymap['<C-8>'] = { function(cmp) cmp.accept { index = 8 } end }
  keymap['<C-9>'] = { function(cmp) cmp.accept { index = 9 } end }
  keymap['<C-0>'] = { function(cmp) cmp.accept { index = 10 } end }
  return keymap
end

local cmdline_opt = {
  enabled = true,

  keymap = {
    ['<C-1>'] = { function(cmp) cmp.accept { index = 1 } end },
    ['<C-2>'] = { function(cmp) cmp.accept { index = 2 } end },
    ['<C-3>'] = { function(cmp) cmp.accept { index = 3 } end },
    ['<C-4>'] = { function(cmp) cmp.accept { index = 4 } end },
    ['<C-5>'] = { function(cmp) cmp.accept { index = 5 } end },
    ['<C-6>'] = { function(cmp) cmp.accept { index = 6 } end },
    ['<C-7>'] = { function(cmp) cmp.accept { index = 7 } end },
    ['<C-8>'] = { function(cmp) cmp.accept { index = 8 } end },
    ['<C-9>'] = { function(cmp) cmp.accept { index = 9 } end },
    ['<C-0>'] = { function(cmp) cmp.accept { index = 10 } end },
  },

  sources = function()
    local type = vim.fn.getcmdtype()
    -- Search forward and backward
    if type == '/' or type == '?' then
      return { 'buffer' }
    end
    -- Commands
    if type == ':' or type == '@' then
      return { 'cmdline' }
    end
    return {}
  end,

  completion = {
    trigger = {
      show_on_blocked_trigger_characters = {},
      show_on_x_blocked_trigger_characters = {},
    },
    list = {
      selection = {
        preselect = true,
        auto_insert = true,
      },
    },
    menu = { auto_show = function(ctx) return vim.fn.getcmdtype() == ':' end },
    ghost_text = { enabled = true },
  },
}

local snippets = {
  preset = 'luasnip',
  expand = function(snippet) require('luasnip').lsp_expand(snippet) end,
  active = function(filter)
    if filter and filter.direction then
      return require('luasnip').jumpable(filter.direction)
    end
    return require('luasnip').in_snippet()
  end,
  jump = function(direction) require('luasnip').jump(direction) end,
}

local completion = {
  menu = {
    draw = {
      columns = { { 'label' }, { 'kind_icon' }, { 'item_idx' } },
      components = {
        item_idx = {
          text = function(ctx) return ctx.idx == 10 and '0' or ctx.idx >= 10 and ' ' or tostring(ctx.idx) end,
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
      fuzzy = { implementation = 'lua' },
      cmdline = cmdline_opt,
    },
  },
}
