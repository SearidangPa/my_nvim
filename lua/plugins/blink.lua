local get_keymap = function()
  local keymap = {}
  keymap.preset = 'none'
  keymap['<C-y>'] = { 'select_and_accept' }
  keymap['<C-p>'] = { 'select_prev', 'fallback' }
  keymap['<C-n>'] = { 'select_next', 'fallback' }
  keymap['<C-b>'] = { 'scroll_documentation_up', 'fallback' }
  keymap['<C-f>'] = { 'scroll_documentation_down', 'fallback' }
  keymap['<C-e>'] = { 'hide' }
  keymap['<Tab>'] = { 'select_next' }
  return keymap
end

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
      columns = { { 'label' }, { 'kind_icon' } },
    },
  },
  documentation = { auto_show = true },
}
return {
  'saghen/blink.cmp',
  lazy = true,
  event = 'InsertCharPre',
  version = '*',

  opts = {
    appearance = { use_nvim_cmp_as_default = true, nerd_font_variant = 'mono' },
    signature = { enabled = true },
    sources = {
      default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
      providers = {
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
        },
      },
    },
    snippets = snippets,
    completion = completion,
    keymap = get_keymap(),
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    cmdline = {
      keymap = { preset = 'inherit' },
      completion = { menu = { auto_show = true } },
    },
  },
}
