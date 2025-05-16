local nvim_treesitter_context = {}

if vim.fn.has 'win32' ~= 1 then
  nvim_treesitter_context = {
    'nvim-treesitter/nvim-treesitter-context',
    lazy = true,
    event = 'VeryLazy',
    opts = {
      enable = true,
      max_lines = 0,
      trim_scope = 'outer',
      min_window_height = 0,
      zindex = 20,
      mode = 'cursor',
      separator = nil,
    },
  },
end

return {
  {
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
  },
  nvim_treesitter_context, -- Context for nvim-treesitter

  -- There are additional nvim-treesitter modules that you can use to interact
  -- with nvim-treesitter. You should go explore a few and see what interests you:
  --
  --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
  --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
  --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
}
