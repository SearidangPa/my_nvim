vim.defer_fn(function()
  local stdpath = vim.fn.stdpath 'config'
  local config_path
  if vim.fn.has 'win32' == 1 then
    config_path = stdpath .. '\\lua\\config'
  else
    config_path = stdpath .. '/lua/config'
  end

  --@diagnostic disable-next-line: param-type-mismatch
  local files = vim.fn.globpath(config_path, '*.lua', true, true)
  for _, file in ipairs(files) do
    local module = vim.fn.fnamemodify(file, ':t:r')
    if not string.match(module, 'util_') then
      require('config.' .. module)
    end
  end
end, 1000)
