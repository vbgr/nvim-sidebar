local t = require("tests.helpers")

local path = require("nvim-sidebar.util.path")

t.test("path utilities normalize and compare paths", function()
  t.assert_equal(path.normalize("/tmp/demo///"), "/tmp/demo")
  t.assert_equal(path.join("/tmp", "demo", "file.txt"), "/tmp/demo/file.txt")
  t.assert_equal(path.basename("/tmp/demo/file.txt"), "file.txt")
  t.assert_equal(path.dirname("/tmp/demo/file.txt"), "/tmp/demo")
  t.assert_equal(path.relative("/tmp/demo", "/tmp/demo/a/b.txt"), "a/b.txt")
  t.assert_true(path.is_descendant("/tmp/demo", "/tmp/demo/a/b.txt"))
  t.assert_false(path.is_descendant("/tmp/demo", "/tmp/other/a.txt"))
  t.assert_equal(path.extension("archive.tar.gz"), "gz")
end)

t.run_if_direct("tests/unit/path_spec.lua")
