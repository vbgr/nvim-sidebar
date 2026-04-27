local t = require("tests.helpers")

local sidebar = require("nvim-sidebar")

t.test("public API exposes documented functions", function()
  t.assert_equal(type(sidebar.setup), "function")
  t.assert_equal(type(sidebar.open), "function")
  t.assert_equal(type(sidebar.close), "function")
  t.assert_equal(type(sidebar.toggle), "function")
  t.assert_equal(type(sidebar.focus), "function")
  t.assert_equal(type(sidebar.refresh), "function")
  t.assert_equal(type(sidebar.locate), "function")
  t.assert_equal(type(sidebar.open_full_tree), "function")
end)

t.run_if_direct("tests/unit/api_spec.lua")
