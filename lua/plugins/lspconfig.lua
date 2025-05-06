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

  -- Auto-format Fish files on save
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*.fish',
    callback = function()
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local content = table.concat(lines, '\n')

      local formatted_content = vim.fn.system('fish_indent', content)
      if vim.v.shell_error ~= 0 then
        vim.notify('Error formatting Fish file: ' .. formatted_content, vim.log.levels.ERROR)
        return
      end

      -- Split the formatted content into lines while preserving empty lines
      local formatted_lines = {}
      -- Remove the last newline if it exists to avoid adding an extra empty line at the end
      if formatted_content:sub(-1) == '\n' then
        formatted_content = formatted_content:sub(1, -2)
      end
      -- Split by newlines and preserve empty lines
      for line in (formatted_content .. '\n'):gmatch '(.-)\n' do
        table.insert(formatted_lines, line)
      end

      vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
      vim.api.nvim_win_set_cursor(0, cursor_pos)
    end,
    desc = 'Format Fish buffer with fish_indent on save while preserving empty lines',
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

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
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

      if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      end
    end,
  })
end

return {
  {
    'williamboman/mason.nvim',
    config = true,
    version = '*',
    lazy = true,
    event = 'WinEnter',
  },
  {
    'williamboman/mason-lspconfig.nvim',
    lazy = true,
    version = '*',
    event = 'WinEnter',
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    lazy = true,
    version = '*',
    event = 'WinEnter',
  },
  {
    'folke/lazydev.nvim',
    lazy = true,
    version = '*',
    event = 'WinEnter',
    ft = 'lua', -- only load for lua files
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
    config = true,
  },
  {
    'neovim/nvim-lspconfig',
    version = '*',
    event = 'VeryLazy',
    config = function()
      attach_auto_import()
      lsp_attach_keybind()
      vim.lsp.enable 'lua_ls'
      vim.lsp.enable 'gopls'
      require 'custom.go_nav_func_decl'
      require 'custom.go_nav_func_expr'
      require 'custom.go_nav_func_equal'
    end,
  },
}
