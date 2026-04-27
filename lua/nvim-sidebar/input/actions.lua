local notify = require("nvim-sidebar.util.notify")
local search = require("nvim-sidebar.search")
local sources = require("nvim-sidebar.sources")
local state = require("nvim-sidebar.state")

local M = {}

local function selected_items(opts)
  if opts ~= nil and opts.range ~= nil then
    return state.get_items_in_range(opts.range.start_line, opts.range.end_line)
  end

  if opts ~= nil and opts.visual then
    return state.get_selected_items()
  end

  local item = state.get_current_item()
  return item ~= nil and { item } or {}
end

local function current_mode()
  if vim.api.nvim_get_current_buf() == state.full.bufnr then
    return "full"
  end

  return "sidebar"
end

function M.dispatch(action, opts)
  local items = selected_items(opts)
  local source_name = items[1] ~= nil and items[1].source or state.active_source
  local mode = current_mode()

  if action == "refresh" then
    require("nvim-sidebar").refresh()
    return
  end

  if action == "close" then
    require("nvim-sidebar").close()
    return
  end

  if action == "search" then
    search.prompt(function()
      require("nvim-sidebar").refresh()
    end)
    return
  end

  if action == "locate" then
    require("nvim-sidebar").locate(source_name)
    return
  end

  local source = sources.get(source_name)
  local handler = source.actions and source.actions[action] or nil

  if handler == nil then
    notify.warn("Action '" .. action .. "' is not available for source '" .. source_name .. "'")
    return
  end

  handler(items[1], {
    items = items,
    mode = mode,
    refresh = function()
      require("nvim-sidebar").refresh()
    end,
  })
end

return M
