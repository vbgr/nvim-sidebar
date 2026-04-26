local t = require("tests.helpers")

local fs_ops = require("nvim-sidebar.fstree.fs_ops")
local path = require("nvim-sidebar.util.path")

t.test("files duplicate creates a file copy next to original", function()
  t.temp_dir("files-duplicate-file", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "dup.txt"), "dup")

    fs_ops.duplicate({
      {
        path = path.join(root, "dup.txt"),
      },
    })

    t.assert_file_exists(path.join(root, "dup.txt copy"))
  end)
end)

t.test("files duplicate recursively copies directories next to original", function()
  t.temp_dir("files-duplicate-dir", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "dir-src", "child.txt"), "child")

    fs_ops.duplicate({
      {
        path = path.join(root, "dir-src"),
      },
    })

    t.assert_file_exists(path.join(root, "dir-src copy", "child.txt"))
  end)
end)

t.run_if_direct("tests/files/duplicate_spec.lua")
