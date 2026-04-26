local path = require("nvim-sidebar.util.path")
local state = require("nvim-sidebar.state")

local M = {}

function M.is_expanded(dir)
  return state.fstree.expanded[path.normalize(dir)] == true
end

function M.expand(dir)
  state.fstree.expanded[path.normalize(dir)] = true
end

function M.collapse(dir)
  state.fstree.expanded[path.normalize(dir)] = nil
end

function M.toggle(dir)
  if M.is_expanded(dir) then
    M.collapse(dir)
  else
    M.expand(dir)
  end
end

function M.collapse_for_item(item)
  if item.kind == "directory" and M.is_expanded(item.path) then
    M.collapse(item.path)
    return item.path
  end

  if item.parent ~= nil then
    M.collapse(item.parent)
    return item.parent
  end

  return item.path
end

return M
