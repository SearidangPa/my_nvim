if vim.fn.has 'win32' == 1 then
  return {}
end

return {
  '3rd/diagram.nvim',
  dependencies = {
    '3rd/image.nvim',
  },
  config = function()
    require('diagram').setup {
      events = {
        render_buffer = { 'InsertLeave' },
        clear_buffer = { 'BufLeave' },
      },
      integrations = {
        require 'diagram.integrations.markdown',
        require 'diagram.integrations.neorg',
      },
      renderer_options = {
        mermaid = {
          theme = 'forest', -- nil | "default" | "dark" | "forest" | "neutral"
          scale = 6, -- nil | 1 (default) | 2  | 3 | ...
          width = 1200, -- nil | 800 | 400 | ...
          height = 1800, -- nil | 600 | 300 | ...
        },
        plantuml = {
          charset = 'utf-8',
        },
        d2 = {
          theme_id = 1,
        },
        gnuplot = {
          theme = 'dark',
          size = '800,600',
        },
      },
    }
  end,
}
