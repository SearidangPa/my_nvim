return {
  {
    'rebelot/kanagawa.nvim',
    event = 'VeryLazy',
    lazy = true,
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    event = 'VeryLazy',
    lazy = true,
  },
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    event = 'VeryLazy',
  },
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    config = function()
      require('rose-pine').setup {
        variant = 'moon',
        disable_italics = true,
      }
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

      local is_light_mode = get_os_mode()

      if is_light_mode then
        vim.o.background = 'light'
        vim.cmd.colorscheme 'github_light_default'
      else
        vim.o.background = 'dark'
        vim.cmd.colorscheme 'rose-pine-moon'
      end
    end,
  },
}
