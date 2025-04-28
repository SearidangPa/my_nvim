return {
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    lazy = true,
  },
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    priority = 1000,
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

      local function save_theme_preference(is_light)
        local file = io.open(cache_file, 'w')
        if file then
          file:write(is_light and 'light' or 'dark')
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

      local function set_theme(is_light_mode)
        if is_light_mode and vim.o.background == 'dark' then
          vim.cmd.colorscheme 'github_light_default'
          vim.o.background = 'light'
        elseif not is_light_mode and vim.o.background == 'light' then
          vim.cmd.colorscheme 'rose-pine-moon'
          vim.o.background = 'dark'
        end
      end

      local is_light_mode = load_prev_theme_preference()
      set_theme(is_light_mode)

      vim.schedule(function()
        local is_light = get_os_mode()
        set_theme(is_light)
        save_theme_preference(is_light)
        vim.api.nvim_set_hl(0, 'Comment', { italic = true, fg = '#6e6a86' })
      end)
    end,
  },
}
