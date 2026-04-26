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

local function buffer_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)

  if name == "" then
    return "[No Name]"
  end

  return vim.fn.fnamemodify(name, ":t")
end

local function listed_buffers()
  local buffers = {}
  local current = state.previous_buffer() or vim.api.nvim_get_current_buf()

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
          current = bufnr == current,
          modified = vim.bo[bufnr].modified,
        })
      end
    end
  end

  return buffers
end

function M.render()
  local lines = {}
  local items = {}
  local highlights = {}

  for _, item in ipairs(listed_buffers()) do
    local icon = devicons.file(item.path, item.name)
    local modified = item.modified and config.options.icons.modified or " "
    local current = item.current and ">" or " "
    local line = string.format("%s %d %s%s %s", current, item.bufnr, icon, modified, item.name)

    table.insert(lines, line)
    items[#lines] = {
      source = "buffers",
      bufnr = item.bufnr,
      name = item.name,
      path = item.path,
    }

    if item.current then
      table.insert(highlights, {
        line = #lines,
        group = "NvimSidebarCurrent",
      })
    end

    if item.modified then
      table.insert(highlights, {
        line = #lines,
        group = "NvimSidebarModified",
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
