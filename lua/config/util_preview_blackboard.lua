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

---@param blackboard_state table
---@param mark_info table
function Open_popup_win(blackboard_state, mark_info)
  local filetype = mark_info.filetype
  local lang = vim.treesitter.language.get_lang(filetype)
  if not pcall(vim.treesitter.start, blackboard_state.popup_buf, lang) then
    vim.bo[blackboard_state.popup_buf].syntax = filetype
  end

  local editor_width = vim.o.columns
  local editor_height = vim.o.lines
  local width = math.floor(editor_width * 4 / 5)
  local height = editor_height - 3
  local row = 1
  local col = 0

  blackboard_state.popup_win = vim.api.nvim_open_win(blackboard_state.popup_buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'none',
  })

  vim.bo[blackboard_state.popup_buf].buftype = 'nofile'
  vim.bo[blackboard_state.popup_buf].bufhidden = 'wipe'
  vim.bo[blackboard_state.popup_buf].swapfile = false
  vim.bo[blackboard_state.popup_buf].filetype = mark_info.filetype
  vim.wo[blackboard_state.popup_win].wrap = false
  vim.wo[blackboard_state.popup_win].number = true
  vim.wo[blackboard_state.popup_win].relativenumber = true
  vim.api.nvim_set_option_value('winhl', 'Normal:Normal', { win = blackboard_state.popup_win }) -- Match background
end
