return {
  'MunifTanjim/nui.nvim',
  event = 'VeryLazy',
  lazy = true,
  {
    'grapp-dev/nui-components.nvim',
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
  },
}
