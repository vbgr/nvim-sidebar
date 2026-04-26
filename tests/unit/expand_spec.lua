local t = require("tests.helpers")

local expand = require("nvim-sidebar.fstree.expand")
local path = require("nvim-sidebar.util.path")

t.test("expand state toggles and collapses parent for files", function()
  t.reset_plugin()

  local root = "/tmp/nvim-sidebar-expand"
  local child = path.join(root, "child")
  local file = path.join(child, "file.txt")

  expand.expand(child)
  t.assert_true(expand.is_expanded(child))
  expand.toggle(child)
  t.assert_false(expand.is_expanded(child))

  expand.expand(child)
  local restore = expand.collapse_for_item({
    kind = "file",
    path = file,
    parent = child,
  })
  t.assert_equal(restore, child)
  t.assert_false(expand.is_expanded(child))
end)

t.run_if_direct("tests/unit/expand_spec.lua")
