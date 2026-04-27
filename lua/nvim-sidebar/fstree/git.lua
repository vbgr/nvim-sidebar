local path = require("nvim-sidebar.util.path")

local M = {}

local function systemlist(args)
  local output = vim.fn.systemlist(args)

  if vim.v.shell_error ~= 0 then
    return nil
  end

  return output
end

local function parse_status(line)
  local status = line:sub(1, 2)
  local relpath = line:sub(4)

  if relpath:find(" -> ", 1, true) then
    relpath = relpath:match(".* %-> (.+)$")
  end

  if status == "??" then
    return relpath, "untracked"
  end

  if status:find("A", 1, true) then
    return relpath, "added"
  end

  if status:find("M", 1, true) or status:find("D", 1, true) then
    return relpath, "modified"
  end

  return relpath, nil
end

function M.status(cwd)
  if vim.fn.executable("git") ~= 1 then
    return {
      root = nil,
      files = {},
    }
  end

  local top = systemlist({
    "git",
    "-C",
    cwd,
    "rev-parse",
    "--show-toplevel",
  })

  if top == nil or top[1] == nil then
    return {
      root = nil,
      files = {},
    }
  end

  local root = path.normalize(top[1])
  local status = systemlist({
    "git",
    "-C",
    cwd,
    "status",
    "--short",
    "--untracked-files=all",
  }) or {}
  local files = {}

  for _, line in ipairs(status) do
    local relpath, kind = parse_status(line)

    if kind ~= nil and relpath ~= nil and relpath ~= "" then
      files[path.join(root, relpath)] = kind
    end
  end

  return {
    root = root,
    files = files,
  }
end

function M.for_path(status, file_path)
  if status == nil or status.root == nil then
    return nil
  end

  return status.files[path.normalize(file_path)]
end

return M
