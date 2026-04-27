local t = require("tests.helpers")

local lualine = require("nvim-sidebar.integrations.lualine")

t.test("lualine integration exposes nvim-sidebar extension shape", function()
  t.assert_equal(lualine.filetypes[1], "nvim-sidebar")
  t.assert_equal(type(lualine.sections.lualine_a[1]), "function")
  t.assert_equal(require("lualine.extensions.nvim-sidebar"), lualine)
end)

t.test("lualine integration renders the sidebar buffer title", function()
  t.reset_editor()

  vim.b.nvim_sidebar_title = "buffers"

  t.assert_equal(lualine.title(), "buffers")
end)

t.test("lualine integration shortens path titles to fit the window", function()
  t.reset_editor()
  vim.cmd("vsplit")
  vim.api.nvim_win_set_width(0, 28)

  vim.b.nvim_sidebar_title = "/tmp/nvim-sidebar-tests/some/deep/project"

  local title = lualine.title()

  t.assert_true(vim.fn.strdisplaywidth(title) <= 21)
  t.assert_contains(title, "project")

  vim.cmd("close")
end)

t.run_if_direct("tests/unit/lualine_spec.lua")
