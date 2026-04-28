local config = require("nvim-sidebar.config")
local expand = require("nvim-sidebar.fstree.expand")
local format = require("nvim-sidebar.util.format")
local fs_ops = require("nvim-sidebar.fstree.fs_ops")
local fuzzy = require("nvim-sidebar.search.fuzzy")
local git = require("nvim-sidebar.fstree.git")
local model = require("nvim-sidebar.fstree.model")
local notify = require("nvim-sidebar.util.notify")
local path = require("nvim-sidebar.util.path")
local state = require("nvim-sidebar.state")
local window = require("nvim-sidebar.ui.window")

local M = {
  name = "files",
}

function M.display_name()
  return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
end

local function current_file_path()
  local bufnr = state.previous_buffer()

  if bufnr == nil then
    return nil
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= "" and path.normalize(name) or nil
end

local function expand_parent_dirs(root, file_path)
  local dir = path.dirname(file_path)

  if dir == root then
    return
  end

  local current = root
  local relative_dir = path.relative(root, dir)

  for part in relative_dir:gmatch("[^/]+") do
    current = path.join(current, part)
    expand.expand(current)
  end
end

local function include_node(node)
  if state.search.query == "" then
    return true
  end

  return fuzzy.match(node.name, state.search.query)
    or fuzzy.match(node.relative_path, state.search.query)
end

local function git_highlight(status)
  if status == "modified" then
    return "NvimSidebarGitModified", config.options.icons.git_modified
  end

  if status == "added" then
    return "NvimSidebarGitAdded", config.options.icons.git_added
  end

  if status == "untracked" then
    return "NvimSidebarGitUntracked", config.options.icons.git_untracked
  end

  return nil, nil
end

local function sidebar_line(node)
  local indent =
    string.rep(" ", config.options.padding_left + node.depth * config.options.tree.indent_width)
  local marker = ""

  if node.kind == "directory" then
    marker = node.expanded and config.options.icons.folder_open
      or config.options.icons.folder_closed
  else
    marker = config.options.icons.file
  end

  local open_marker = node.open_buffer and (" " .. config.options.icons.buffer_open) or ""
  local icon = node.icon ~= "" and (node.icon .. " ") or ""

  return indent .. marker .. " " .. icon .. node.name .. open_marker
end

local function sidebar_icon_columns(node)
  if node.icon == "" then
    return nil, nil
  end

  local prefix = string.rep(
    " ",
    config.options.padding_left + node.depth * config.options.tree.indent_width
  ) .. config.options.icons.file .. " "
  local col_start = #prefix

  return col_start, col_start + #node.icon
end

local function pad_left(value, width)
  local padding = width - vim.fn.strdisplaywidth(value)

  if padding <= 0 then
    return value
  end

  return string.rep(" ", padding) .. value
end

local function pad_right(value, width)
  local padding = width - vim.fn.strdisplaywidth(value)

  if padding <= 0 then
    return value
  end

  return value .. string.rep(" ", padding)
end

local function full_column_value(node, column)
  if column == "size" then
    return node.kind == "directory" and config.options.tree.directory_size or format.size(node.size)
  end

  if column == "type" then
    return node.kind == "directory" and config.options.tree.directory_type or node.extension
  end

  if column == "modified" then
    return format.mtime(node.mtime, config.options.tree.date_format)
  end

  return ""
end

local function full_column_widths(nodes)
  local widths = {}

  for _, node in ipairs(nodes) do
    if include_node(node) then
      for _, column in ipairs(config.options.tree.full_columns) do
        local width = vim.fn.strdisplaywidth(full_column_value(node, column))
        widths[column] = math.max(widths[column] or 0, width)
      end
    end
  end

  return widths
end

local function full_line(node, widths)
  local columns = {}

  for _, column in ipairs(config.options.tree.full_columns) do
    local value = full_column_value(node, column)

    if column == "size" then
      table.insert(columns, pad_left(value, widths[column] or 0))
    else
      table.insert(columns, pad_right(value, widths[column] or 0))
    end
  end

  local left = sidebar_line(node)
  local right = table.concat(columns, "  ")
  local width = vim.api.nvim_win_get_width(0)
  local git_marker_margin = 4
  local padding = width
    - vim.fn.strdisplaywidth(left)
    - vim.fn.strdisplaywidth(right)
    - git_marker_margin

  if padding < 2 then
    padding = 2
  end

  return left .. string.rep(" ", padding) .. right
end

local function action_mode(ctx)
  if ctx ~= nil and ctx.mode ~= nil then
    return ctx.mode
  end

  if vim.api.nvim_get_current_buf() == state.full.bufnr then
    return "full"
  end

  return "sidebar"
end

local function refresh_sidebar_preserving_current_window(ctx)
  if ctx == nil or ctx.refresh == nil then
    return
  end

  local current_winid = vim.api.nvim_get_current_win()
  local sidebar_winid = state.sidebar.winid

  if sidebar_winid ~= nil and vim.api.nvim_win_is_valid(sidebar_winid) then
    vim.api.nvim_set_current_win(sidebar_winid)
    ctx.refresh()

    if vim.api.nvim_win_is_valid(current_winid) then
      vim.api.nvim_set_current_win(current_winid)
    end

    return
  end

  ctx.refresh()
end

function M.render(ctx)
  local root = vim.fn.getcwd()
  local git_status = git.status(root)
  local nodes = model.visible(root, {
    git = git_status,
  })
  local lines = {}
  local items = {}
  local highlights = {}
  local column_widths = ctx.mode == "full" and full_column_widths(nodes) or {}

  for _, node in ipairs(nodes) do
    if include_node(node) then
      table.insert(
        lines,
        ctx.mode == "full" and full_line(node, column_widths) or sidebar_line(node)
      )

      items[#lines] = {
        source = "files",
        kind = node.kind,
        path = node.path,
        name = node.name,
        parent = node.parent,
      }

      if node.kind == "directory" then
        table.insert(highlights, {
          line = #lines,
          group = "NvimSidebarDirectory",
        })
      end

      local icon_col_start, icon_col_end = sidebar_icon_columns(node)

      if icon_col_start ~= nil then
        table.insert(highlights, {
          line = #lines,
          group = node.icon_highlight or "NvimSidebarFileIcon",
          col_start = icon_col_start,
          col_end = icon_col_end,
        })
      end

      local group, marker = git_highlight(node.git_status)

      if marker ~= nil then
        table.insert(highlights, {
          line = #lines,
          group = group,
          virt_text = marker,
        })
      end
    end
  end

  if #lines == 0 then
    lines = {
      "No files",
    }
  end

  return {
    lines = lines,
    items = items,
    highlights = highlights,
  }
end

M.actions = {}

function M.actions.locate()
  local file_path = current_file_path()

  if file_path == nil then
    notify.warn("Current buffer has no file path")
    return
  end

  local root = path.normalize(vim.fn.getcwd())

  if not path.is_descendant(root, file_path) then
    notify.warn("Current file is outside cwd: " .. file_path)
    return
  end

  state.search.query = ""
  state.cursor.restore_path = file_path
  state.cursor.restore_bufnr = nil
  expand_parent_dirs(root, file_path)
end

local function open_item(item, ctx)
  if item == nil then
    return false, nil, nil
  end

  local mode = action_mode(ctx)

  if item.kind == "directory" then
    expand.toggle(item.path)
    state.cursor.restore_path = item.path
    ctx.refresh()
    return true, "directory", mode
  end

  if mode == "full" then
    window.close_full()
  else
    local winid = state.previous_window()

    if winid ~= nil then
      vim.api.nvim_set_current_win(winid)
    end
  end

  vim.cmd.edit(vim.fn.fnameescape(item.path))

  if mode == "sidebar" then
    refresh_sidebar_preserving_current_window(ctx)
  end

  return true, "file", mode
end

function M.actions.open(item, ctx)
  open_item(item, ctx)
end

function M.actions.open_and_close(item, ctx)
  local opened, kind, mode = open_item(item, ctx)

  if opened and kind == "file" and mode == "sidebar" then
    window.close_sidebar()
  end
end

function M.actions.collapse(item, ctx)
  if item == nil then
    return
  end

  local restore_path = expand.collapse_for_item(item)
  state.cursor.restore_path = restore_path
  ctx.refresh()
end

function M.actions.new_file(item, ctx)
  fs_ops.new_file(item, ctx.refresh)
end

function M.actions.new_directory(item, ctx)
  fs_ops.new_directory(item, ctx.refresh)
end

function M.actions.rename(item, ctx)
  fs_ops.rename(item, function(target)
    state.cursor.restore_path = target
    ctx.refresh()
  end)
end

function M.actions.trash(item, ctx)
  fs_ops.trash(ctx.items)
  ctx.refresh()
end

function M.actions.copy(item, ctx)
  fs_ops.copy(ctx.items)
end

function M.actions.cut(item, ctx)
  fs_ops.cut(ctx.items)
end

function M.actions.paste(item, ctx)
  fs_ops.paste(item, ctx.refresh)
end

function M.actions.yank_name(item, ctx)
  fs_ops.yank_name(ctx.items)
end

function M.actions.yank_path(item, ctx)
  fs_ops.yank_path(ctx.items)
end

function M.actions.duplicate(item, ctx)
  fs_ops.duplicate(ctx.items)
  ctx.refresh()
end

return M
