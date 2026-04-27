local state = require("nvim-sidebar.state")

local M = {}

function M.restore(bufnr)
  if state.cursor.restore_path == nil and state.cursor.restore_bufnr == nil then
    return
  end

  local items = state.line_items[bufnr] or {}

  for line, item in pairs(items) do
    if
      (state.cursor.restore_path ~= nil and item.path == state.cursor.restore_path)
      or (state.cursor.restore_bufnr ~= nil and item.bufnr == state.cursor.restore_bufnr)
    then
      pcall(vim.api.nvim_win_set_cursor, 0, {
        line,
        0,
      })
      state.cursor.restore_path = nil
      state.cursor.restore_bufnr = nil
      return
    end
  end

  state.cursor.restore_path = nil
  state.cursor.restore_bufnr = nil
end

return M
