local t = require("tests.helpers")

local config = require("nvim-sidebar.config")
local fuzzy = require("nvim-sidebar.search.fuzzy")

t.test("fuzzy search matches in order", function()
  config.setup()
  t.assert_true(fuzzy.match("README.md", "rme"))
  t.assert_true(fuzzy.match("README.md", "read"))
  t.assert_false(fuzzy.match("README.md", "zzz"))
end)

t.test("fuzzy search supports case-sensitive matching", function()
  config.setup({
    search = {
      case_sensitive = true,
    },
  })

  t.assert_false(fuzzy.match("README.md", "read"))
end)

t.run_if_direct("tests/unit/fuzzy_spec.lua")
