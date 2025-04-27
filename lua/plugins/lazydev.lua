return {
  'folke/lazydev.nvim',
  ft = 'lua', -- only load for lua files
  opts = {
    library = {
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
    },
  },
  config = true,
}
