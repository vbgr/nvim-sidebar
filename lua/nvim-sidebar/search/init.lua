local state = require("nvim-sidebar.state")

local M = {}

local active = false
local refresh_callback = nil
local autocmds_created = false

local function run_callback(callback)
  if callback ~= nil then
    callback()
  end
end

local function set_query(query, callback)
  query = query or ""

  if state.search.query == query then
    return
  end

  state.search.query = query
  run_callback(callback)
end

local function commandline_abort()
  local event = vim.v.event or {}

  return event.abort == true or event.abort == 1
end

local function ensure_autocmds()
  if autocmds_created then
    return
  end

  local group = vim.api.nvim_create_augroup("NvimSidebarSearch", {
    clear = true,
  })

  vim.api.nvim_create_autocmd("CmdlineChanged", {
    group = group,
    pattern = "/",
    callback = function()
      M.update(vim.fn.getcmdline())
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    pattern = "/",
    callback = function()
      M.finish(commandline_abort(), vim.fn.getcmdline())
    end,
  })

  autocmds_created = true
end

function M.start(callback)
  ensure_autocmds()

  active = true
  refresh_callback = callback
  state.search.query = ""
  run_callback(refresh_callback)

  vim.api.nvim_feedkeys("/", "n", false)
end

function M.update(query)
  if not active then
    return
  end

  set_query(query, refresh_callback)
end

function M.finish(aborted, query)
  if not active then
    return
  end

  local callback = refresh_callback

  active = false
  refresh_callback = nil

  if aborted then
    M.clear(callback)
    return
  end

  set_query(query, callback)
end

function M.clear(callback)
  if state.search.query ~= "" then
    state.search.query = ""
  end

  run_callback(callback)
end

return M
