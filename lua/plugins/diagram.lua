if vim.fn.has 'win32' == 1 then
  return {}
end

return {
  'searidangPa/diagram.nvim',
  dependencies = {
    '3rd/image.nvim',
  },
  config = function()
    require('diagram').setup {
      events = {
        render_buffer = { 'TextChanged' },
        clear_buffer = { 'BufLeave', 'InsertEnter' },
      },
      integrations = {
        require 'diagram.integrations.markdown',
      },
      renderer_options = {
        mermaid = {
          theme = 'default', -- nil | "default" | "dark" | "forest" | "neutral"
          scale = 3, -- nil | 1 (default) | 2  | 3 | ...
          width = 1000, -- nil | 800 | 400 | ...
          height = 600, -- nil | 600 | 300 | ...
        },
      },
    }
  end,
}
