local config = require("nvim-sidebar.config")
local devicons = require("nvim-sidebar.integrations.devicons")
local fuzzy = require("nvim-sidebar.search.fuzzy")
local notify = require("nvim-sidebar.util.notify")
local state = require("nvim-sidebar.state")

local M = {
  name = "buffers",
}

local current_ns = vim.api.nvim_create_namespace("nvim-sidebar-current-buffer")

function M.display_name()
  return "buffers"
end

local function buf_is_valid(bufnr)
  return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

local function buffer_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)

  if name == "" then
    return "[No Name]"
  end

  return vim.fn.fnamemodify(name, ":t")
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
    local line =
      string.format("%s%s %s%s%s", padding, buffer_number, icon_with_space, modified, item.name)

    table.insert(lines, line)
    items[#lines] = {
      source = "buffers",
      bufnr = item.bufnr,
      name = item.name,
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

function M.update_current_highlight(bufnr)
  bufnr = bufnr or state.sidebar.bufnr

  if not buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, current_ns, 0, -1)

  local current_bufnr = state.previous_buffer()

  if current_bufnr == nil then
    return
  end

  for line, item in pairs(state.line_items[bufnr] or {}) do
    if item.source == "buffers" and item.bufnr == current_bufnr then
      vim.api.nvim_buf_set_extmark(bufnr, current_ns, line - 1, 0, {
        line_hl_group = "NvimSidebarCurrentBuffer",
        priority = 80,
      })
      return
    end
  end
end

function M.after_render(bufnr)
  M.update_current_highlight(bufnr)
end

M.actions = {}

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
