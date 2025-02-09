return {
  'folke/flash.nvim',
  event = 'VeryLazy',
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
          keys = { 'f', 'F', 't', 'T', [';'] = 'l', [','] = 'h' },
          highlight = { backdrop = false },
        },
      },
    }
    require('flash').setup(opts)
    vim.api.nvim_set_hl(0, 'FlashMatch', { fg = '#5097A4' })
  end,
}
