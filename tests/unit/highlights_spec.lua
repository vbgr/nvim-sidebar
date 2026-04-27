local t = require("tests.helpers")

local highlights = require("nvim-sidebar.ui.highlights")

t.test("highlights registers current buffer group", function()
  highlights.setup()

  t.assert_equal(vim.fn.hlexists("NvimSidebarCurrentBuffer"), 1)
end)

t.run_if_direct("tests/unit/highlights_spec.lua")
