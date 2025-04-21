return {
  {
    'rebelot/kanagawa.nvim',
    event = 'VeryLazy',
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    event = 'VeryLazy',
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
      local handle = io.popen 'defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light"'
      assert(handle, 'Failed to run command')
      local result = handle:read '*a'
      handle:close()

      if result:match 'Dark' then
        vim.o.background = 'dark'
        vim.cmd.colorscheme 'rose-pine-moon'
      else
        vim.o.background = 'light'
        vim.cmd.colorscheme 'github_light_default'
      end
    end,
  },
}
