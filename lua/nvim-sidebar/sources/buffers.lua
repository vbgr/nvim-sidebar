local config = require("nvim-sidebar.config")
local devicons = require("nvim-sidebar.integrations.devicons")
local fuzzy = require("nvim-sidebar.search.fuzzy")
local notify = require("nvim-sidebar.util.notify")
local state = require("nvim-sidebar.state")

local M = {
  name = "buffers",
}

function M.display_name()
  return "buffers"
end

local function buf_is_valid(bufnr)
  return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

local function win_is_valid(winid)
  return winid ~= nil and vim.api.nvim_win_is_valid(winid)
end

local function current_tabpage()
  return vim.api.nvim_get_current_tabpage()
end

local function win_is_in_current_tab(winid)
  return win_is_valid(winid) and vim.api.nvim_win_get_tabpage(winid) == current_tabpage()
end

local function visible_buffer_window(bufnr)
  local remembered = state.buffer_window(bufnr)

  if remembered ~= nil and vim.api.nvim_win_get_buf(remembered) == bufnr then
    return remembered
  end

  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    if win_is_in_current_tab(winid) and state.is_editor_window(winid) then
      return winid
    end
  end

  return nil
end

local function first_editor_window()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if state.is_editor_window(winid) then
      return winid
    end
  end

  return nil
end

local function target_window(bufnr)
  local visible = visible_buffer_window(bufnr)

  if visible ~= nil then
    return visible
  end

  local remembered = state.buffer_window(bufnr)

  if remembered ~= nil then
    return remembered
  end

  local previous = state.previous_window()

  if state.is_editor_window(previous) then
    return previous
  end

  return first_editor_window()
end

local function switch_buffer_in_owner_window(bufnr)
  if not buf_is_valid(bufnr) then
    return false
  end

  local sidebar_winid = vim.api.nvim_get_current_win()
  local winid = target_window(bufnr)

  if winid == nil then
    notify.warn("No editor window available for buffer")
    return false
  end

  local ok, err = pcall(vim.api.nvim_win_set_buf, winid, bufnr)

  if not ok then
    notify.warn("Could not switch buffer: " .. tostring(err))
    return false
  end

  state.remember_window(winid)

  if win_is_valid(sidebar_winid) then
    pcall(vim.api.nvim_set_current_win, sidebar_winid)
  end

  return true
end

local function buffer_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)

  if name == "" then
    return "[No Name]"
  end

  return vim.fn.fnamemodify(name, ":t")
end

local function parent_name(buffer_path)
  if buffer_path == "" then
    return nil
  end

  local parent = vim.fn.fnamemodify(buffer_path, ":h:t")

  return parent ~= "" and parent or nil
end

local function apply_duplicate_labels(buffers)
  local counts = {}

  for _, item in ipairs(buffers) do
    counts[item.name] = (counts[item.name] or 0) + 1
  end

  for _, item in ipairs(buffers) do
    item.display_name = item.name

    if counts[item.name] > 1 then
      local parent = parent_name(item.path)

      if parent ~= nil then
        item.display_name = parent .. "/" .. item.name
      end
    end
  end
end

local function listed_buffers()
  local buffers = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      local buffer_path = vim.api.nvim_buf_get_name(bufnr)
      local name = buffer_name(bufnr)

      if
        state.search.query == ""
        or fuzzy.match(name, state.search.query)
        or fuzzy.match(buffer_path, state.search.query)
      then
        table.insert(buffers, {
          bufnr = bufnr,
          name = name,
          path = buffer_path,
          modified = vim.bo[bufnr].modified,
        })
      end
    end
  end

  apply_duplicate_labels(buffers)

  return buffers
end

local function icon_text(icon)
  return icon ~= "" and (icon .. " ") or ""
end

local function buffer_number_text(bufnr)
  return string.format("%2d", bufnr)
end

function M.render()
  local lines = {}
  local items = {}
  local highlights = {}

  for _, item in ipairs(listed_buffers()) do
    local icon, icon_highlight = devicons.file(item.path, item.name)
    local icon_with_space = icon_text(icon)
    local modified = item.modified and (config.options.icons.modified .. " ") or ""
    local padding = string.rep(" ", config.options.padding_left)
    local buffer_number = buffer_number_text(item.bufnr)
    local line = string.format(
      "%s%s %s%s%s",
      padding,
      buffer_number,
      icon_with_space,
      modified,
      item.display_name
    )

    table.insert(lines, line)
    items[#lines] = {
      source = "buffers",
      bufnr = item.bufnr,
      name = item.display_name,
      path = item.path,
    }

    if icon ~= "" then
      local col_start = #(padding .. buffer_number .. " ")

      table.insert(highlights, {
        line = #lines,
        group = icon_highlight or "NvimSidebarFileIcon",
        col_start = col_start,
        col_end = col_start + #icon,
      })
    end

    if item.modified then
      local col_start = #(padding .. buffer_number .. " " .. icon_with_space)

      table.insert(highlights, {
        line = #lines,
        group = "NvimSidebarModified",
        col_start = col_start,
        col_end = col_start + #config.options.icons.modified,
      })
    end
  end

  if #lines == 0 then
    lines = {
      "No buffers",
    }
  end

  return {
    lines = lines,
    items = items,
    highlights = highlights,
  }
end

function M.sync_current_cursor(bufnr)
  bufnr = bufnr or state.sidebar.bufnr

  if not buf_is_valid(bufnr) or not win_is_valid(state.sidebar.winid) then
    return
  end

  if vim.api.nvim_win_get_buf(state.sidebar.winid) ~= bufnr then
    return
  end

  local current_bufnr = state.previous_buffer()

  if current_bufnr == nil then
    return
  end

  for line, item in pairs(state.line_items[bufnr] or {}) do
    if item.source == "buffers" and item.bufnr == current_bufnr then
      pcall(vim.api.nvim_win_set_cursor, state.sidebar.winid, {
        line,
        0,
      })
      return
    end
  end
end

function M.after_render(bufnr)
  M.sync_current_cursor(bufnr)
end

M.actions = {}

local function buffer_rows()
  local rows = {}
  local bufnr = vim.api.nvim_get_current_buf()

  for line, item in pairs(state.line_items[bufnr] or {}) do
    if item.source == "buffers" and buf_is_valid(item.bufnr) then
      table.insert(rows, {
        line = line,
        item = item,
      })
    end
  end

  table.sort(rows, function(left, right)
    return left.line < right.line
  end)

  return rows
end

local function adjacent_buffer_row(direction)
  local rows = buffer_rows()

  if #rows == 0 then
    return nil
  end

  local current_line = vim.api.nvim_win_get_cursor(0)[1]

  if direction > 0 then
    for _, row in ipairs(rows) do
      if row.line > current_line then
        return row
      end
    end

    return rows[1]
  end

  for index = #rows, 1, -1 do
    if rows[index].line < current_line then
      return rows[index]
    end
  end

  return rows[#rows]
end

local function switch_adjacent_buffer(direction)
  local row = adjacent_buffer_row(direction)

  if row == nil then
    return
  end

  vim.api.nvim_win_set_cursor(0, {
    row.line,
    0,
  })
  switch_buffer_in_owner_window(row.item.bufnr)
end

function M.actions.locate()
  local bufnr = state.previous_buffer()

  if bufnr == nil then
    notify.warn("No buffer to locate")
    return
  end

  state.search.query = ""
  state.cursor.restore_path = nil
  state.cursor.restore_bufnr = bufnr
end

function M.actions.open(item)
  if item == nil or not vim.api.nvim_buf_is_valid(item.bufnr) then
    return
  end

  local winid = state.previous_window()

  if winid ~= nil then
    vim.api.nvim_set_current_win(winid)
  end

  vim.api.nvim_set_current_buf(item.bufnr)
end

function M.actions.next_buffer()
  switch_adjacent_buffer(1)
end

function M.actions.previous_buffer()
  switch_adjacent_buffer(-1)
end

function M.actions.yank_name(item, ctx)
  local names = {}

  for _, selected in ipairs(ctx.items) do
    table.insert(names, selected.name)
  end

  if #names == 0 and item ~= nil then
    table.insert(names, item.name)
  end

  vim.fn.setreg(vim.v.register, table.concat(names, "\n"))
end

return M
