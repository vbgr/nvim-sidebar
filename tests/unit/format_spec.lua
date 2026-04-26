local t = require("tests.helpers")

local format = require("nvim-sidebar.util.format")

t.test("format utilities render sizes and timestamps", function()
  t.assert_equal(format.size(512), "512B")
  t.assert_equal(format.size(1536), "1.5K")
  t.assert_equal(format.size(1024 * 1024), "1.0M")
  t.assert_equal(
    format.mtime({
      sec = 0,
    }, "%Y"),
    "1970"
  )
end)

t.run_if_direct("tests/unit/format_spec.lua")
