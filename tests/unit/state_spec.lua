local t = require("tests.helpers")

local state = require("nvim-sidebar.state")
local path = require("nvim-sidebar.util.path")

t.test("state tracks current and ranged line items", function()
  t.reset_plugin()

  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
    "one",
    "two",
    "three",
  })
  state.set_items(bufnr, {
    {
      name = "one",
    },
    {
      name = "two",
    },
    {
      name = "three",
    },
  })

  vim.api.nvim_win_set_cursor(0, {
    2,
    0,
  })
  t.assert_equal(state.get_current_item().name, "two")

  local selected = state.get_items_in_range(3, 1)

  t.assert_equal(#selected, 3)
  t.assert_equal(selected[1].name, "one")
  t.assert_equal(selected[2].name, "two")
  t.assert_equal(selected[3].name, "three")
end)

t.test("state remembers previous non-plugin window and buffer", function()
  t.reset_plugin()

  local winid = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()

  state.remember_current_window()

  t.assert_equal(state.previous_window(), winid)
  t.assert_equal(state.previous_buffer(), bufnr)

  state.sidebar.bufnr = bufnr
  state.remember_current_window()

  t.assert_equal(state.previous_window(), winid)
  t.assert_equal(state.previous_buffer(), bufnr)
end)

t.test("state tracks buffer owner windows in the current tab", function()
  t.temp_dir("state-buffer-owners", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_winid = vim.api.nvim_get_current_win()
    local alpha_bufnr = vim.api.nvim_get_current_buf()

    vim.cmd("vsplit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    local beta_winid = vim.api.nvim_get_current_win()
    local beta_bufnr = vim.api.nvim_get_current_buf()

    state.previous.winid = alpha_winid
    state.previous.bufnr = alpha_bufnr
    state.remember_current_tab_windows()

    t.assert_equal(state.previous_window(), alpha_winid)
    t.assert_equal(state.previous_buffer(), alpha_bufnr)
    t.assert_equal(state.buffer_window(alpha_bufnr), alpha_winid)
    t.assert_equal(state.buffer_window(beta_bufnr), beta_winid)

    state.sidebar.bufnr = beta_bufnr
    vim.api.nvim_set_current_win(beta_winid)
    state.remember_current_window()

    t.assert_equal(state.previous_window(), alpha_winid)
    t.assert_equal(state.previous_buffer(), alpha_bufnr)
  end)
end)

t.run_if_direct("tests/unit/state_spec.lua")
