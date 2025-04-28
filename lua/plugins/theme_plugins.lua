return {
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    lazy = true,
  },
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('rose-pine').setup {
        variant = 'moon',
      }
      vim.cmd.colorscheme 'rose-pine-moon'

      -- vim.defer_fn(function()
      --   local function get_os_mode()
      --     local is_light = true
      --
      --     if vim.fn.has 'win32' == 1 then
      --       local result = vim.fn.system 'reg query "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize" /v AppsUseLightTheme'
      --       is_light = not result:match '0x0'
      --     else
      --       local result = vim.fn.system 'defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light"'
      --       is_light = not result:match 'Dark'
      --     end
      --
      --     return is_light
      --   end
      --
      --   local is_light_mode = get_os_mode()
      --
      --   if is_light_mode then
      --     vim.o.background = 'light'
      --     vim.cmd.colorscheme 'github_light_default'
      --   end
      --   vim.api.nvim_set_hl(0, 'Comment', { italic = true, fg = '#6e6a86' })
      -- end, 0)
    end,
  },
}
