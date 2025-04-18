local function attach_auto_import()
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*.go',

    callback = function()
      local params = vim.lsp.util.make_range_params()

      local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params)

      for cid, res in pairs(result or {}) do
        for _, r in pairs(res.result or {}) do
          if r.edit then
            local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or 'utf-16'
            vim.lsp.util.apply_workspace_edit(r.edit, enc)
          end
        end
      end

      vim.lsp.buf.format { async = false }
    end,
  })
end

local function lsp_attach_keybind()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, {
          buffer = event.buf,
          desc = 'LSP: ' .. desc,
        })
      end
      map('gd', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
      map('<localleader>r', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
      map('<localleader>d', require('telescope.builtin').lsp_definitions, '[G]oto [D]eclaration')

      map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
      map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
      map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })

        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      end
    end,
  })
end

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    {
      'folke/lazydev.nvim',
      ft = 'lua', -- only load for lua files
      opts = {
        library = {
          { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        },
      },
    },
  },

  config = function()
    attach_auto_import()
    lsp_attach_keybind()

    local capabilities = require('blink.cmp').get_lsp_capabilities()
    require('lspconfig').gopls.setup { capabilities = capabilities }
    require('lspconfig').marksman.setup { capabilities = capabilities }
    require('lspconfig').lua_ls.setup { capabilities = capabilities }
  end,
}
