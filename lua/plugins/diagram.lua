if vim.fn.has 'win32' == 1 then
  return {}
end

return {
  'searidangPa/diagram.nvim',
  dependencies = {
    '3rd/image.nvim',
  },
  config = function()
    local diagram = require 'diagram'
    diagram.setup {
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
          height = 800, -- nil | 600 | 300 | ...
        },
      },
    }

    local mini_notify = require 'mini.notify'
    local make_notify = mini_notify.make_notify {}

    -- Function to delete all descendants of a directory
    local function clear_directory(dir)
      -- Check if directory exists
      if vim.fn.isdirectory(dir) == 1 then
        -- Get all items in the directory
        local items = vim.fn.readdir(dir)

        -- Iterate through each item
        for _, item in ipairs(items) do
          local item_path = dir .. '/' .. item

          -- If it's a directory, use recursive delete
          if vim.fn.isdirectory(item_path) == 1 then
            vim.fn.delete(item_path, 'rf')
          else
            -- If it's a file, delete it
            vim.fn.delete(item_path)
          end
        end

        return true
      end

      return false
    end

    local cache_dir = diagram.get_cache_dir()
    vim.api.nvim_create_user_command('ClearDiagramCache', function()
      -- Clear the cache directory
      local cache_dir = vim.fn.resolve(vim.fn.stdpath 'cache' .. '/diagram-cache/mermaid')
      local success = clear_directory(cache_dir)
      if success then
        make_notify(string.format('Cache directory cleared: %s', cache_dir))
      else
        make_notify(string.format('Failed to clear cache directory: %s', cache_dir), vim.log.levels.ERROR)
      end
    end, {})
  end,
}
