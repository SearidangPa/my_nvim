return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  lazy = true,
  event = 'VeryLazy',
  main = 'nvim-treesitter.configs', -- Sets main module to use for opts
  opts = {
    ensure_installed = { 'go', 'lua' },
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = { 'ruby' },
    },
    indent = { enable = true, disable = { 'ruby' } },
    matchup = { enable = true },
  },

  -- There are additional nvim-treesitter modules that you can use to interact
  -- with nvim-treesitter. You should go explore a few and see what interests you:
  --
  --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
  --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
  --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
}
