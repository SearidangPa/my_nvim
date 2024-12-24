return {
  'tjdevries/present.nvim',
  config = function()
    vim.api.nvim_create_user_command('PresentMarkdown', function()
      require('present').start_presentation {}
    end, {})
  end,
}
