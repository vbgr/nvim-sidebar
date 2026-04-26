local state = require("nvim-sidebar.state")

local M = {}

function M.set(mode, paths)
  state.fstree.clipboard.mode = mode
  state.fstree.clipboard.paths = paths or {}
end

function M.get()
  return {
    mode = state.fstree.clipboard.mode,
    paths = vim.deepcopy(state.fstree.clipboard.paths),
  }
end

function M.clear()
  state.fstree.clipboard.mode = nil
  state.fstree.clipboard.paths = {}
end

return M
