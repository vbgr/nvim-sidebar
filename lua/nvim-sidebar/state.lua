local M = {}

M.sidebar = {
  bufnr = nil,
  winid = nil,
}

M.full = {
  bufnr = nil,
  winid = nil,
}

M.previous = {
  bufnr = nil,
  winid = nil,
}

M.active_source = nil
M.render_mode = "sidebar"
M.line_items = {}
M.search = {
  query = "",
}

M.cursor = {
  restore_path = nil,
  restore_bufnr = nil,
}

M.fstree = {
  expanded = {},
  clipboard = {
    mode = nil,
    paths = {},
  },
}

local function win_is_valid(winid)
  return winid ~= nil and vim.api.nvim_win_is_valid(winid)
end

local function buf_is_valid(bufnr)
  return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

function M.is_plugin_buffer(bufnr)
  return bufnr ~= nil and (bufnr == M.sidebar.bufnr or bufnr == M.full.bufnr)
end

function M.remember_current_window()
  local winid = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()

  if M.is_plugin_buffer(bufnr) then
    return
  end

  M.previous.winid = winid
  M.previous.bufnr = bufnr
end

function M.previous_window()
  if win_is_valid(M.previous.winid) then
    return M.previous.winid
  end

  return nil
end

function M.previous_buffer()
  if buf_is_valid(M.previous.bufnr) then
    return M.previous.bufnr
  end

  return nil
end

function M.set_items(bufnr, items)
  M.line_items[bufnr] = items or {}
end

function M.get_current_item()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1]

  return M.line_items[bufnr] and M.line_items[bufnr][line] or nil
end

function M.get_items_in_range(start_line, end_line)
  local bufnr = vim.api.nvim_get_current_buf()
  local items = M.line_items[bufnr] or {}

  if start_line == nil or end_line == nil then
    return {}
  end

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local selected = {}

  for line = start_line, end_line do
    if items[line] ~= nil then
      table.insert(selected, items[line])
    end
  end

  return selected
end

function M.get_selected_items()
  return M.get_items_in_range(vim.fn.line("'<"), vim.fn.line("'>"))
end

return M
