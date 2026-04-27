local clipboard = require("nvim-sidebar.fstree.clipboard")
local config = require("nvim-sidebar.config")
local notify = require("nvim-sidebar.util.notify")
local path = require("nvim-sidebar.util.path")

local M = {}

local uv = vim.uv or vim.loop

local function item_paths(items)
  local paths = {}

  for _, item in ipairs(items or {}) do
    if item.path ~= nil then
      table.insert(paths, item.path)
    end
  end

  return paths
end

local function parent_dir(item)
  if item == nil then
    return vim.fn.getcwd()
  end

  if item.kind == "directory" then
    return item.path
  end

  return path.dirname(item.path)
end

local function command_executable(command)
  local executable = command[1]

  return executable ~= nil and executable ~= "" and vim.fn.executable(executable) == 1
end

local function unique_path(target)
  if uv.fs_stat(target) == nil then
    return target
  end

  local index = 2

  while true do
    local candidate = string.format("%s %d", target, index)

    if uv.fs_stat(candidate) == nil then
      return candidate
    end

    index = index + 1
  end
end

local function paste_target(destination, source)
  local target = path.join(destination, path.basename(source))

  if uv.fs_stat(target) == nil then
    return target
  end

  return unique_path(target .. " copy")
end

local function copy_recursive(source, target)
  local stat = uv.fs_stat(source)

  if stat == nil then
    return false, "source does not exist: " .. source
  end

  if stat.type == "directory" then
    vim.fn.mkdir(target, "p")

    local handle = uv.fs_scandir(source)

    if handle == nil then
      return true
    end

    while true do
      local name = uv.fs_scandir_next(handle)

      if name == nil then
        break
      end

      local ok, err = copy_recursive(path.join(source, name), path.join(target, name))

      if not ok then
        return false, err
      end
    end

    return true
  end

  local ok, err = uv.fs_copyfile(source, target)

  if not ok then
    return false, err
  end

  return true
end

local function prompt_path(prompt, base_dir, callback)
  vim.ui.input({
    prompt = prompt,
  }, function(input)
    if input == nil or input == "" then
      return
    end

    callback(path.join(base_dir, input))
  end)
end

function M.new_file(item, refresh)
  prompt_path("New file: ", parent_dir(item), function(target)
    if uv.fs_stat(target) ~= nil then
      notify.warn("File already exists: " .. target)
      return
    end

    vim.fn.mkdir(path.dirname(target), "p")
    vim.fn.writefile({}, target)

    if refresh ~= nil then
      refresh()
    end
  end)
end

function M.new_directory(item, refresh)
  prompt_path("New directory: ", parent_dir(item), function(target)
    vim.fn.mkdir(target, "p")

    if refresh ~= nil then
      refresh()
    end
  end)
end

function M.rename(item, refresh)
  if item == nil or item.path == nil then
    return
  end

  vim.ui.input({
    prompt = "Rename: ",
    default = item.name,
  }, function(input)
    if input == nil or input == "" then
      return
    end

    local target = path.join(path.dirname(item.path), input)

    if target == item.path then
      return
    end

    if uv.fs_stat(target) ~= nil then
      notify.warn("File already exists: " .. target)
      return
    end

    local ok, result = pcall(vim.fn.rename, item.path, target)

    if not ok then
      notify.error(result)
      return
    end

    if result ~= 0 then
      notify.error("Failed to rename: " .. item.path)
      return
    end

    if refresh ~= nil then
      refresh(target)
    end
  end)
end

function M.trash(items)
  local paths = item_paths(items)

  if #paths == 0 then
    return
  end

  if config.options.trash_cmd == nil then
    notify.warn("trash_cmd is not configured")
    return
  end

  local command = type(config.options.trash_cmd) == "table"
      and vim.deepcopy(config.options.trash_cmd)
    or { config.options.trash_cmd }

  if not command_executable(command) then
    notify.error("trash_cmd is not executable: " .. tostring(command[1]))
    return
  end

  for _, selected_path in ipairs(paths) do
    local ok, result = pcall(
      vim.fn.system,
      vim.list_extend(vim.deepcopy(command), {
        selected_path,
      })
    )

    if not ok then
      notify.error(result)
      return
    end

    if vim.v.shell_error ~= 0 then
      notify.error(result)
    end
  end
end

function M.copy(items)
  clipboard.set("copy", item_paths(items))
end

function M.cut(items)
  clipboard.set("cut", item_paths(items))
end

function M.paste(item, refresh)
  local data = clipboard.get()

  if data.mode == nil or #data.paths == 0 then
    return
  end

  local destination = parent_dir(item)

  for _, source in ipairs(data.paths) do
    local target = paste_target(destination, source)

    if data.mode == "cut" then
      local ok, result = pcall(vim.fn.rename, source, target)

      if not ok then
        notify.error(result)
      elseif result ~= 0 then
        notify.error("Failed to move: " .. source)
      end
    else
      local ok, err = copy_recursive(source, target)

      if not ok then
        notify.error(err)
      end
    end
  end

  if data.mode == "cut" then
    clipboard.clear()
  end

  if refresh ~= nil then
    refresh()
  end
end

function M.duplicate(items)
  for _, source in ipairs(item_paths(items)) do
    local target = unique_path(path.join(path.dirname(source), path.basename(source) .. " copy"))
    local ok, err = copy_recursive(source, target)

    if not ok then
      notify.error(err)
    end
  end
end

function M.yank_name(items)
  local names = {}

  for _, selected_path in ipairs(item_paths(items)) do
    table.insert(names, path.basename(selected_path))
  end

  vim.fn.setreg(vim.v.register, table.concat(names, "\n"))
end

function M.yank_path(items)
  local cwd = vim.fn.getcwd()
  local paths = {}

  for _, selected_path in ipairs(item_paths(items)) do
    table.insert(paths, path.relative(cwd, selected_path))
  end

  vim.fn.setreg(vim.v.register, table.concat(paths, "\n"))
end

return M
