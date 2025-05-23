return {
  {
    'neovim/nvim-lspconfig',
    version = '*',
    event = 'VeryLazy',
    config = function()
      local function attach_auto_import()
        vim.api.nvim_create_autocmd('BufWritePre', {
          pattern = '*.go',
          callback = function()
            local clients = vim.lsp.get_clients()
            local position_encoding_for_params
            if clients and #clients > 0 then
              for _, client in ipairs(clients) do
                if client and client.offset_encoding and type(client.offset_encoding) == 'string' then
                  position_encoding_for_params = client.offset_encoding
                  break
                end
              end
            end

            local params = vim.lsp.util.make_range_params(0, position_encoding_for_params)
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

      local function format_fish_file()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local content = table.concat(lines, '\n')

        -- First, check for syntax errors before attempting to format
        local syntax_check = vim.fn.system('fish -n', content)
        if vim.v.shell_error ~= 0 then
          vim.notify('Fish syntax error detected: ' .. syntax_check, vim.log.levels.WARN)
          -- Don't attempt to format if there are syntax errors
          return
        end

        local formatted_content = vim.fn.system('fish_indent', content)
        if vim.v.shell_error ~= 0 then
          vim.notify('Error formatting Fish file: ' .. formatted_content, vim.log.levels.ERROR)
          return
        end

        local formatted_lines = {}
        -- Remove the last newline if it exists to avoid adding an extra empty line at the end
        if formatted_content:sub(-1) == '\n' then
          formatted_content = formatted_content:sub(1, -2)
        end
        -- Split by newlines
        for line in (formatted_content .. '\n'):gmatch '(.-)\n' do
          table.insert(formatted_lines, line)
        end

        vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
      end

      local fish_format_group = vim.api.nvim_create_augroup('FishFormatting', { clear = true })
      local function setup_fish_formatting()
        vim.api.nvim_create_autocmd('BufWritePost', {
          group = fish_format_group,
          pattern = '*.fish',
          callback = format_fish_file,
          desc = 'Format Fish buffer with fish_indent on save while preserving empty lines',
        })
      end

      vim.api.nvim_create_user_command('FishFormatDisable', function()
        vim.api.nvim_clear_autocmds { group = fish_format_group }
        vim.notify('Fish auto-formatting disabled', vim.log.levels.INFO)
      end, {
        desc = 'Disable automatic Fish file formatting on save',
      })

      -- Create user command to reattach (enable) fish formatting
      vim.api.nvim_create_user_command('FishFormatEnable', function()
        vim.api.nvim_clear_autocmds { group = fish_format_group }
        setup_fish_formatting()
        vim.notify('Fish auto-formatting enabled', vim.log.levels.INFO)
      end, {
        desc = 'Enable automatic Fish file formatting on save',
      })

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

      attach_auto_import()
      lsp_attach_keybind()
      setup_fish_formatting()
      vim.lsp.enable 'lua_ls'
      vim.lsp.enable 'gopls'
      require 'custom.go_nav_func_decl'
      require 'custom.go_nav_func_expr'
      require 'custom.go_nav_func_equal'
    end,
  },

  {
    'williamboman/mason.nvim',
    config = true,
    version = '*',
    lazy = true,
    event = { 'VeryLazy' },
  },
  {
    'folke/lazydev.nvim',
    lazy = true,
    version = '*',
    ft = 'lua', -- only load for lua files
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
    config = true,
  },
}
