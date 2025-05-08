return {
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    lazy = true,
    event = 'VeryLazy',
  },
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    lazy = false,
    priority = 100000,
    config = function()
      require('rose-pine').setup {
        variant = 'moon',
      }
      local cache_file = vim.fn.stdpath 'cache' .. '/theme_preference.txt'

      local function get_os_mode()
        local is_light = true
        if vim.fn.has 'win32' == 1 then
          local result = vim.fn.system 'reg query "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize" /v AppsUseLightTheme'
          is_light = not result:match '0x0'
        else
          local result = vim.fn.system 'defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light"'
          is_light = not result:match 'Dark'
        end
        return is_light
      end

      ---@class thmeme.opts
      ---@field is_light_mode boolean

      --- @param opts thmeme.opts
      local function save_theme_preference(opts)
        local is_light_mode = opts.is_light_mode or false
        local file = io.open(cache_file, 'w')
        if file then
          file:write(is_light_mode and 'light' or 'dark')
          file:close()
        end
      end

      local function load_prev_theme_preference()
        local file = io.open(cache_file, 'r')
        if file then
          local content = file:read()
          file:close()
          return content == 'light'
        end
        return false
      end

      local function lualine_refresh(theme_name)
        require('lualine').setup {
          options = {
            theme = theme_name,
          },
        }
      end

      ---@param opts thmeme.opts
      local function set_theme(opts)
        local is_light_mode = opts.is_light_mode or false
        if is_light_mode and vim.g.colors_name ~= 'github_light_default' then
          require 'github-theme'
          vim.cmd.colorscheme 'github_light_default'
          lualine_refresh 'github_light_default'
        elseif not is_light_mode and vim.g.colors_name ~= 'rose-pine' then
          vim.cmd.colorscheme 'rose-pine-moon'
          lualine_refresh 'rose-pine-moon'
        end
        save_theme_preference { is_light_mode = is_light_mode_from_os }
      end

      vim.api.nvim_set_hl(0, 'Comment', { italic = true, fg = '#6e6a86' })

      if not vim.g.colors_name then -- at startup
        local is_light_mode = load_prev_theme_preference()
        set_theme { is_light_mode = is_light_mode }
      end

      vim.schedule(function()
        local is_light_mode_from_os = get_os_mode()
        set_theme { is_light_mode = is_light_mode_from_os }
      end)

      vim.keymap.set('n', '<localleader>cl', function() set_theme { is_light_mode = true } end, { desc = 'Colorscheme [L]ight' })
      vim.keymap.set('n', '<localleader>cr', function() set_theme { is_light_mode = false } end, { desc = 'Colorscheme [R]ose-Pine' })
    end,
  },
}
