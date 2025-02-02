-- lifted from nvim-bqf
local api = vim.api
local fn = vim.fn
local cmd = vim.cmd

---@param bufnrFrom number
---@param bufnrTo number
function TransferBuf(bufnrFrom, bufnrTo)
  local function transferFile(rb, wb)
    local ePath = fn.fnameescape(api.nvim_buf_get_name(rb))
    local ok, msg = pcall(api.nvim_buf_call, wb, function()
      cmd(([[ noa call deletebufline(%d, 1, '$') ]]):format(wb))
      cmd(([[ noa sil 0read %s ]]):format(ePath))
      cmd(([[ noa call deletebufline(%d, '$') ]]):format(wb))
    end)
    return ok, msg
  end

  local fromLoaded = api.nvim_buf_is_loaded(bufnrFrom)
  if fromLoaded then
    if vim.bo[bufnrFrom].modified then
      local lines = api.nvim_buf_get_lines(bufnrFrom, 0, -1, false)
      api.nvim_buf_set_lines(bufnrTo, 0, -1, false, lines)
    else
      if not transferFile(bufnrFrom, bufnrTo) then
        local lines = api.nvim_buf_get_lines(bufnrFrom, 0, -1, false)
        api.nvim_buf_set_lines(bufnrTo, 0, -1, false, lines)
      end
    end
  else
    local ok, msg = transferFile(bufnrFrom, bufnrTo)
    if not ok and msg:match [[:E484: Can't open file]] then
      cmd(('noa call bufload(%d)'):format(bufnrFrom))
      local lines = api.nvim_buf_get_lines(bufnrFrom, 0, -1, false)
      cmd(('noa bun %d'):format(bufnrFrom))
      api.nvim_buf_set_lines(bufnrTo, 0, -1, false, lines)
    end
  end
  vim.bo[bufnrTo].modified = false
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
  local width = math.floor(editor_width * 3 / 4)
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

---@param mark_char string
---@param blackboard_state table
---@param target_line number
local function set_cursor_for_popup_win(blackboard_state, target_line, mark_char)
  local line_count = vim.api.nvim_buf_line_count(blackboard_state.popup_buf)
  if target_line >= line_count then
    target_line = line_count
  end
  vim.api.nvim_win_set_cursor(blackboard_state.popup_win, { target_line, 2 }) -- Move cursor after the arrow

  vim.fn.sign_define('MySign', { text = mark_char, texthl = 'DiagnosticInfo' })
  vim.fn.sign_place(0, 'MySignGroup', 'MySign', blackboard_state.popup_buf, { lnum = target_line, priority = 100 })
end

---@param blackboard_state table
local function show_fullscreen_popup_at_mark(blackboard_state)
  local mark_char = Get_mark_char(blackboard_state)
  if not mark_char then
    return
  end
  if blackboard_state.current_mark == mark_char and vim.api.nvim_win_is_valid(blackboard_state.popup_win) then
    return
  end
  blackboard_state.current_mark = mark_char

  local mark_info = Retrieve_mark_info(mark_char)
  local target_line = mark_info.line
  local filepath_bufnr = mark_info.bufnr

  if vim.api.nvim_win_is_valid(blackboard_state.popup_win) then
    TransferBuf(filepath_bufnr, blackboard_state.popup_buf)
    set_cursor_for_popup_win(blackboard_state, target_line, mark_char)
    return
  end

  blackboard_state.popup_buf = vim.api.nvim_create_buf(false, true)
  TransferBuf(filepath_bufnr, blackboard_state.popup_buf)
  Open_popup_win(blackboard_state, mark_info)
  set_cursor_for_popup_win(blackboard_state, target_line, mark_char)
end

---@param blackboard_state table
function Create_autocmd(blackboard_state)
  local augroup = vim.api.nvim_create_augroup('blackboard_group', { clear = true })

  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = blackboard_state.blackboard_buf,
    group = augroup,
    callback = function()
      show_fullscreen_popup_at_mark(blackboard_state)
      vim.api.nvim_set_current_win(blackboard_state.blackboard_win)
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufLeave', 'WinLeave' }, {
    buffer = blackboard_state.blackboard_buf,
    group = augroup,
    callback = function()
      if vim.api.nvim_win_is_valid(blackboard_state.popup_win) then
        vim.api.nvim_win_close(blackboard_state.popup_win, true)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = blackboard_state.blackboard_buf,
    group = augroup,
    callback = function()
      if vim.api.nvim_get_current_win() == blackboard_state.blackboard_win then
        vim.api.nvim_win_set_buf(blackboard_state.original_win, blackboard_state.original_buf)
        vim.defer_fn(function()
          if vim.api.nvim_win_is_valid(blackboard_state.blackboard_win) then
            vim.api.nvim_set_current_win(blackboard_state.original_win)
            vim.api.nvim_win_set_buf(blackboard_state.blackboard_win, blackboard_state.blackboard_buf)
          end
        end, 0)
      end
    end,
  })
  vim.keymap.set('n', '<CR>', function()
    require('config.blackboard').jump_to_mark(blackboard_state)
  end, { noremap = true, silent = true, buffer = blackboard_state.blackboard_buf })
end
