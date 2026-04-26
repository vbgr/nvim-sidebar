local t = require("tests.helpers")

t.test("setup registers documented user commands", function()
  t.reset_plugin()

  local commands = vim.api.nvim_get_commands({})

  t.assert_true(commands.NvimSidebar ~= nil)
  t.assert_true(commands.NvimSidebarToggle ~= nil)
  t.assert_true(commands.NvimSidebarRefresh ~= nil)
  t.assert_true(commands.NvimSidebarLocate ~= nil)
  t.assert_true(commands.NvimSidebarTree ~= nil)
  t.assert_equal(commands.NvimSidebar.nargs, "?")
  t.assert_equal(commands.NvimSidebarToggle.nargs, "?")
  t.assert_equal(commands.NvimSidebarLocate.nargs, "?")
end)

t.run_if_direct("tests/unit/commands_spec.lua")
