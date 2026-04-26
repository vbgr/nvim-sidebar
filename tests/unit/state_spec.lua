local t = require("tests.helpers")

local state = require("nvim-sidebar.state")

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

t.run_if_direct("tests/unit/state_spec.lua")
