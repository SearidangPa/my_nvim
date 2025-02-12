return {
  'Goose97/timber.nvim',
  version = '*', -- Use for stability; omit to use `main` branch for the latest features
  event = 'VeryLazy',
  config = function()
    local opts = {
      log_templates = {
        default = {
          go = [[log.Printf("=====================> %log_target: %v\n", %log_target)]],
        },
      },
    }
    require('timber').setup(opts)
  end,
}
