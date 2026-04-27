local t = require("tests.helpers")

local path = require("nvim-sidebar.util.path")
local state = require("nvim-sidebar.state")
local window = require("nvim-sidebar.ui.window")

local function other_window(winid)
  for _, current in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if current ~= winid then
      return current
    end
  end

  return nil
end

local function listed_editor_buffers()
  local buffers = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_valid(bufnr)
      and vim.bo[bufnr].buflisted
      and not state.is_plugin_buffer(bufnr)
    then
      table.insert(buffers, bufnr)
    end
  end

  return buffers
end

t.test("open_sidebar reuses existing window and reapplies configured width", function()
  t.reset_plugin({
    width = 30,
  })

  local first_winid = window.open_sidebar()
  local editor_winid = other_window(first_winid)

  assert(editor_winid ~= nil, "expected an editor window next to the sidebar")

  vim.api.nvim_win_set_width(first_winid, 12)
  vim.api.nvim_set_current_win(editor_winid)

  local second_winid = window.open_sidebar()

  t.assert_equal(second_winid, first_winid)
  t.assert_equal(vim.api.nvim_get_current_win(), first_winid)
  t.assert_equal(vim.api.nvim_win_get_width(first_winid), 30)
end)

t.test("focus_sidebar returns nil when closed and focuses sidebar when open", function()
  t.reset_plugin()

  t.assert_equal(window.focus_sidebar(), nil)

  local sidebar_winid = window.open_sidebar()
  local editor_winid = other_window(sidebar_winid)

  assert(editor_winid ~= nil, "expected an editor window next to the sidebar")

  vim.api.nvim_set_current_win(editor_winid)

  t.assert_equal(window.focus_sidebar(), sidebar_winid)
  t.assert_equal(vim.api.nvim_get_current_win(), sidebar_winid)
end)

t.test("close_sidebar is a no-op when sidebar is closed", function()
  t.reset_plugin()

  window.close_sidebar()

  t.assert_false(window.is_sidebar_open())
  t.assert_equal(#vim.api.nvim_tabpage_list_wins(0), 1)
end)

t.test("close_sidebar_if_last_regular_window keeps sidebar when called from sidebar", function()
  t.reset_plugin()

  local sidebar_winid = window.open_sidebar()

  window.close_sidebar_if_last_regular_window()

  t.assert_true(window.is_sidebar_open())
  t.assert_true(vim.api.nvim_win_is_valid(sidebar_winid))
  t.assert_equal(vim.api.nvim_get_current_win(), sidebar_winid)
end)

t.test("ensure_default_editor_buffer creates listed buffer when editors are unlisted", function()
  t.reset_plugin()
  vim.bo.buflisted = false

  local bufnr = window.ensure_default_editor_buffer()

  t.assert_equal(vim.api.nvim_get_current_buf(), bufnr)
  t.assert_true(vim.bo[bufnr].buflisted)
  t.assert_equal(#listed_editor_buffers(), 1)
  t.assert_equal(state.previous_window(), vim.api.nvim_get_current_win())
  t.assert_equal(state.previous_buffer(), bufnr)
end)

t.test("close_full restores previous editor buffer and clears full state", function()
  t.temp_dir("window-close-full", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))

    local editor_bufnr = vim.api.nvim_get_current_buf()

    state.remember_current_window()
    window.open_full()

    local full_bufnr = state.full.bufnr

    window.close_full()

    t.assert_equal(vim.api.nvim_get_current_buf(), editor_bufnr)
    t.assert_false(vim.api.nvim_buf_is_valid(full_bufnr))
    t.assert_equal(state.full.bufnr, nil)
    t.assert_equal(state.full.winid, nil)
  end)
end)

t.test("close_full clears stale full state when full buffer is invalid", function()
  t.reset_plugin()

  local full_bufnr = vim.api.nvim_create_buf(false, true)

  state.full.bufnr = full_bufnr
  state.full.winid = vim.api.nvim_get_current_win()

  vim.api.nvim_buf_delete(full_bufnr, {
    force = true,
  })

  window.close_full()

  t.assert_equal(state.full.bufnr, nil)
  t.assert_equal(state.full.winid, nil)
end)

t.run_if_direct("tests/unit/window_spec.lua")
