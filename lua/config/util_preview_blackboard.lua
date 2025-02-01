-- lifted from nvim-bqf
local api = vim.api
local fn = vim.fn
local cmd = vim.cmd
function TransferBuf(from, to)
  local function transferFile(rb, wb)
    local ePath = fn.fnameescape(api.nvim_buf_get_name(rb))
    local ok, msg = pcall(api.nvim_buf_call, wb, function()
      cmd(([[ noa call deletebufline(%d, 1, '$') ]]):format(wb))
      cmd(([[ noa sil 0read %s ]]):format(ePath))
      cmd(([[ noa call deletebufline(%d, '$') ]]):format(wb))
    end)
    return ok, msg
  end

  local fromLoaded = api.nvim_buf_is_loaded(from)
  if fromLoaded then
    if vim.bo[from].modified then
      local lines = api.nvim_buf_get_lines(from, 0, -1, false)
      api.nvim_buf_set_lines(to, 0, -1, false, lines)
    else
      if not transferFile(from, to) then
        local lines = api.nvim_buf_get_lines(from, 0, -1, false)
        api.nvim_buf_set_lines(to, 0, -1, false, lines)
      end
    end
  else
    local ok, msg = transferFile(from, to)
    if not ok and msg:match [[:E484: Can't open file]] then
      cmd(('noa call bufload(%d)'):format(from))
      local lines = api.nvim_buf_get_lines(from, 0, -1, false)
      cmd(('noa bun %d'):format(from))
      api.nvim_buf_set_lines(to, 0, -1, false, lines)
    end
  end
  vim.bo[to].modified = false
end
