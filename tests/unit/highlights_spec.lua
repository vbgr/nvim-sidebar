local t = require("tests.helpers")

local highlights = require("nvim-sidebar.ui.highlights")

t.test("highlights registers sidebar highlight groups", function()
  highlights.setup()

  t.assert_equal(vim.fn.hlexists("NvimSidebarFileIcon"), 1)
  t.assert_equal(vim.fn.hlexists("NvimSidebarDirectory"), 1)
  t.assert_equal(vim.fn.hlexists("NvimSidebarSearch"), 1)
end)

t.test("highlights links indent guides to NonText by default", function()
  highlights.setup()

  local hl = vim.api.nvim_get_hl(0, {
    name = "NvimSidebarIndent",
    link = true,
  })

  t.assert_equal(hl.link, "NonText")
end)

t.run_if_direct("tests/unit/highlights_spec.lua")
