local commands = require("nvim-sidebar.commands")
local config = require("nvim-sidebar.config")
local highlights = require("nvim-sidebar.ui.highlights")
local keymaps = require("nvim-sidebar.input.keymaps")
local render = require("nvim-sidebar.ui.render")
local sources = require("nvim-sidebar.sources")
local state = require("nvim-sidebar.state")
local window = require("nvim-sidebar.ui.window")

local M = {}

local initialized = false
local pending_buffer_deletes = 0

local function sync_buffers_current_cursor()
  if not window.is_sidebar_open() or state.active_source ~= "buffers" then
    return
  end

  sources.get("buffers").sync_current_cursor()
end

local function refresh_buffers_sidebar()
  if not window.is_sidebar_open() or state.active_source ~= "buffers" then
    return
  end

  render.render_source(sources.get("buffers"), "sidebar")
  keymaps.apply(state.sidebar.bufnr)
end

local function handle_buffer_delete()
  pending_buffer_deletes = pending_buffer_deletes + 1

  vim.schedule(function()
    local ok, err = xpcall(function()
      if window.is_sidebar_open() then
        window.ensure_default_editor_buffer()
      end

      refresh_buffers_sidebar()
    end, debug.traceback)

    pending_buffer_deletes = math.max(pending_buffer_deletes - 1, 0)

    if not ok then
      error(err)
    end
  end)
end

local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("NvimSidebar", {
    clear = true,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      state.remember_current_window()
      sync_buffers_current_cursor()
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = handle_buffer_delete,
  })

  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    callback = function()
      window.close_sidebar_if_last_regular_window()
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function()
      vim.schedule(function()
        if pending_buffer_deletes > 0 then
          return
        end

        window.close_if_sidebar_is_last_window()
      end)
    end,
  })
end

local function ensure_setup()
  if not initialized then
    M.setup()
  end
end

local function active_source(source_name)
  local name = sources.resolve(source_name or state.active_source)
  state.active_source = name
  return sources.get(name)
end

function M.setup(opts)
  config.setup(opts)
  state.active_source = sources.resolve(config.options.default_source)
  highlights.setup()
  commands.setup()
  setup_autocmds()
  initialized = true
  return config.options
end

function M.open(source_name)
  ensure_setup()
  state.remember_current_window()

  local source = active_source(source_name)
  local winid = window.open_sidebar()

  render.render_source(source, "sidebar")
  keymaps.apply(state.sidebar.bufnr)

  return winid
end

function M.close()
  ensure_setup()

  if vim.api.nvim_get_current_buf() == state.full.bufnr then
    window.close_full()
    return
  end

  window.close_sidebar()
end

function M.toggle(source_name)
  ensure_setup()

  if window.is_sidebar_open() and (source_name == nil or source_name == state.active_source) then
    window.close_sidebar()
    return
  end

  return M.open(source_name)
end

function M.focus()
  ensure_setup()
  return window.focus_sidebar()
end

function M.refresh()
  ensure_setup()

  if window.is_sidebar_open() then
    render.render_source(active_source(), "sidebar")
    keymaps.apply(state.sidebar.bufnr)
  end

  if window.is_full_open() then
    render.render_source(sources.get("files"), "full")
    keymaps.apply(state.full.bufnr)
  end
end

function M.locate(source_name)
  ensure_setup()
  state.remember_current_window()

  local source = active_source(source_name)

  if source.actions ~= nil and source.actions.locate ~= nil then
    source.actions.locate()
  end

  return M.open(source.name)
end

function M.open_full_tree()
  ensure_setup()
  state.remember_current_window()

  local winid = window.open_full()
  render.render_source(sources.get("files"), "full")
  keymaps.apply(state.full.bufnr)

  return winid
end

return M
