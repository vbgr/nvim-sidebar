local config = require("nvim-sidebar.config")
local path = require("nvim-sidebar.util.path")

local M = {}

local uv = vim.uv or vim.loop

local function excluded(name)
  for _, pattern in ipairs(config.options.tree.exclude_patterns) do
    if name:find(pattern) ~= nil then
      return true
    end
  end

  return false
end

function M.scan(dir)
  local handle = uv.fs_scandir(dir)

  if handle == nil then
    return {}
  end

  local entries = {}

  while true do
    local name, kind = uv.fs_scandir_next(handle)

    if name == nil then
      break
    end

    if not excluded(name) then
      local full_path = path.join(dir, name)
      local stat = uv.fs_stat(full_path)

      table.insert(entries, {
        name = name,
        path = path.normalize(full_path),
        kind = kind == "directory" and "directory" or "file",
        stat = stat,
      })
    end
  end

  table.sort(entries, function(left, right)
    if left.kind ~= right.kind then
      return left.kind == "directory"
    end

    return left.name:lower() < right.name:lower()
  end)

  return entries
end

return M
