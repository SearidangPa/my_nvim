return {
  'folke/flash.nvim',
  lazy = true,
  event = 'VeryLazy',
  version = '*',
  -- stylua: ignore
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
  },

  config = function()
    local opts = {
      highlight = {
        backdrop = false,
      },
      modes = {
        char = {
          autohide = true,
          keys = { 'f', 'F', 't', 'T', [';'] = 'L', [','] = 'H' },
          highlight = {
            backdrop = false,
          },
        },
      },
    }
    require('flash').setup(opts)
  end,
}
