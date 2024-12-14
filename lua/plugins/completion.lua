return { -- Autocompletion
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    require 'plugins.luasnip',
    'saadparwaiz1/cmp_luasnip',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-path',
  },
  config = function()
    local cmp = require 'cmp'
    local luasnip = require 'luasnip'
    luasnip.config.setup {}

    cmp.setup {
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = { completeopt = 'menu,menuone,noinsert' },

      mapping = cmp.mapping.preset.insert {
        ['<C-l>'] = cmp.mapping(function()
          local accept = vim.fn['copilot#Accept']
          local res = accept(vim.api.nvim_replace_termcodes('<Tab>', true, true, false))
          res = res .. '\n'
          vim.api.nvim_feedkeys(res, 'n', false)
        end),

        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-y>'] = cmp.mapping.confirm { select = true },

        ['<CR>'] = cmp.mapping.confirm { select = false, behavior = cmp.ConfirmBehavior.Replace },
        ['<Tab>'] = cmp.mapping.select_next_item(),
        ['<S-Tab>'] = cmp.mapping.select_prev_item(),

        ['<C-B>'] = cmp.mapping.scroll_docs(-4),
        ['<C-F>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete {},
      },
      sources = {
        {
          name = 'lazydev',
          -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
          group_index = 0,
        },
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'path' },
      },
    }
  end,
}
