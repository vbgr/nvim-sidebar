local devicons = require("nvim-sidebar.integrations.devicons")
local expand = require("nvim-sidebar.fstree.expand")
local git = require("nvim-sidebar.fstree.git")
local path = require("nvim-sidebar.util.path")
local scanner = require("nvim-sidebar.fstree.scanner")

local M = {}

local function file_icon(entry)
  if entry.kind == "directory" then
    return "", nil
  end

  return devicons.file(entry.path, entry.name)
end

local function open_buffer_paths()
  local paths = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)

    if name ~= "" and vim.api.nvim_buf_is_loaded(bufnr) then
      paths[path.normalize(name)] = true
    end
  end

  return paths
end

local function collect(nodes, root, dir, depth, open_buffers, git_status)
  for _, entry in ipairs(scanner.scan(dir)) do
    local is_directory = entry.kind == "directory"
    local icon, icon_highlight = file_icon(entry)
    local relative_path = path.relative(root, entry.path)
    local stat = entry.stat or {}
    local node = {
      kind = entry.kind,
      name = entry.name,
      path = entry.path,
      parent = dir,
      relative_path = relative_path,
      depth = depth,
      expanded = is_directory and expand.is_expanded(entry.path) or false,
      open_buffer = open_buffers[entry.path] or false,
      git_status = git.for_path(git_status, entry.path),
      icon = icon,
      icon_highlight = icon_highlight,
      size = stat.size,
      extension = is_directory and "" or path.extension(entry.name),
      mtime = stat.mtime,
    }

    table.insert(nodes, node)

    if is_directory and node.expanded then
      collect(nodes, root, entry.path, depth + 1, open_buffers, git_status)
    end
  end
end

function M.visible(root, opts)
  root = path.normalize(root)

  local nodes = {}

  collect(nodes, root, root, 0, open_buffer_paths(), opts.git)

  return nodes
end

return M
