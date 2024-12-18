return {
  'MeanderingProgrammer/markdown.nvim',
  dependencies = { 'nvim-treesitter' },
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
}
