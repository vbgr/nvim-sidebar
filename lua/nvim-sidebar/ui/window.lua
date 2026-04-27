local buffer = require("nvim-sidebar.ui.buffer")
local config = require("nvim-sidebar.config")
local state = require("nvim-sidebar.state")

local M = {}

local function win_is_valid(winid)
  return winid ~= nil and vim.api.nvim_win_is_valid(winid)
end

local function buf_is_valid(bufnr)
  return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

local full_window_options = {
  "number",
  "relativenumber",
  "signcolumn",
  "wrap",
  "list",
  "spell",
  "foldenable",
  "cursorline",
  "statusline",
}

local function save_window_options(winid)
  local options = {}

  for _, name in ipairs(full_window_options) do
    options[name] = vim.wo[winid][name]
  end

  return options
end

local function restore_window_options(winid, options)
  if not win_is_valid(winid) or options == nil then
    return
  end

  for name, value in pairs(options) do
    pcall(function()
      vim.wo[winid][name] = value
    end)
  end
end

local function apply_window_options(winid)
  vim.wo[winid].number = false
  vim.wo[winid].relativenumber = false
  vim.wo[winid].signcolumn = "no"
  vim.wo[winid].wrap = false
  vim.wo[winid].list = false
  vim.wo[winid].spell = false
  vim.wo[winid].foldenable = false
  vim.wo[winid].cursorline = true
end

local function statusline_title(title)
  return " " .. title:gsub("%%", "%%%%")
end

function M.is_sidebar_open()
  return win_is_valid(state.sidebar.winid)
end

function M.is_full_open()
  return win_is_valid(state.full.winid)
end

function M.is_sidebar_window(winid)
  return win_is_valid(winid)
    and state.sidebar.bufnr ~= nil
    and vim.api.nvim_win_get_buf(winid) == state.sidebar.bufnr
end

local function current_tab_wins()
  return vim.api.nvim_tabpage_list_wins(0)
end

function M.open_sidebar()
  if M.is_sidebar_open() then
    vim.api.nvim_set_current_win(state.sidebar.winid)
    vim.api.nvim_win_set_width(state.sidebar.winid, config.options.width)
    apply_window_options(state.sidebar.winid)
    return state.sidebar.winid
  end

  local split_cmd = config.options.side == "right" and "botright vertical split"
    or "topleft vertical split"

  vim.cmd(split_cmd)

  state.sidebar.winid = vim.api.nvim_get_current_win()
  state.sidebar.bufnr = buffer.ensure_sidebar()

  vim.api.nvim_win_set_buf(state.sidebar.winid, state.sidebar.bufnr)
  vim.api.nvim_win_set_width(state.sidebar.winid, config.options.width)
  apply_window_options(state.sidebar.winid)

  return state.sidebar.winid
end

function M.set_title(mode, title)
  local winid = mode == "full" and state.full.winid or state.sidebar.winid

  if not win_is_valid(winid) then
    return
  end

  vim.wo[winid].statusline = statusline_title(title)
end

function M.close_sidebar()
  if not M.is_sidebar_open() then
    return
  end

  if #current_tab_wins() == 1 and M.is_sidebar_window(state.sidebar.winid) then
    vim.cmd.quit()
    return
  end

  vim.api.nvim_win_close(state.sidebar.winid, true)
  state.sidebar.winid = nil
end

function M.close_sidebar_if_last_regular_window()
  if not M.is_sidebar_open() then
    return
  end

  local current_winid = vim.api.nvim_get_current_win()

  if M.is_sidebar_window(current_winid) then
    return
  end

  local non_sidebar_wins = {}

  for _, winid in ipairs(current_tab_wins()) do
    if not M.is_sidebar_window(winid) then
      table.insert(non_sidebar_wins, winid)
    end
  end

  if #non_sidebar_wins == 1 and non_sidebar_wins[1] == current_winid then
    vim.api.nvim_win_close(state.sidebar.winid, true)
    state.sidebar.winid = nil
  end
end

function M.close_if_sidebar_is_last_window()
  if not M.is_sidebar_open() then
    return
  end

  local wins = current_tab_wins()

  if #wins == 1 and M.is_sidebar_window(wins[1]) then
    state.sidebar.winid = wins[1]
    vim.cmd.quit()
  end
end

function M.focus_sidebar()
  if not M.is_sidebar_open() then
    return nil
  end

  vim.api.nvim_set_current_win(state.sidebar.winid)
  return state.sidebar.winid
end

function M.open_full()
  local previous = state.previous_window()

  if previous ~= nil then
    vim.api.nvim_set_current_win(previous)
  end

  state.full.winid = vim.api.nvim_get_current_win()
  state.full.window_options = save_window_options(state.full.winid)
  state.full.bufnr = buffer.ensure_full()

  vim.api.nvim_win_set_buf(state.full.winid, state.full.bufnr)
  apply_window_options(state.full.winid)

  return state.full.winid
end

function M.close_full()
  local full_winid = state.full.winid
  local full_bufnr = state.full.bufnr
  local window_options = state.full.window_options

  if not buf_is_valid(full_bufnr) then
    restore_window_options(full_winid, window_options)
    state.full.bufnr = nil
    state.full.winid = nil
    state.full.window_options = nil
    return
  end

  local previous_bufnr = state.previous_buffer()

  if win_is_valid(full_winid) then
    if previous_bufnr ~= nil and previous_bufnr ~= full_bufnr then
      vim.api.nvim_win_set_buf(full_winid, previous_bufnr)
    else
      vim.api.nvim_set_current_win(full_winid)
      vim.cmd.enew()
    end

    restore_window_options(full_winid, window_options)
  end

  pcall(vim.api.nvim_buf_delete, full_bufnr, {
    force = true,
  })

  state.full.bufnr = nil
  state.full.winid = nil
  state.full.window_options = nil
end

return M
