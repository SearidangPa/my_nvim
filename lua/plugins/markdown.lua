return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    opts = {},
    config = function()
      require('render-markdown').setup {
        heading = {
          sign = false,
          backgrounds = {
            'RenderMarkdownH2Bg',
            'RenderMarkdownH1Bg',
            'RenderMarkdownH2Bg',
          },
        },
      }
    end,
  },
}
