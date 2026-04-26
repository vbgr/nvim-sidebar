local t = require("tests.helpers")

local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")

t.test("files visual trash mapping sends all selected paths to configured command", function()
  t.temp_dir("files-trash", function(root)
    t.reset_plugin({
      trash_cmd = {
        "sh",
        "-c",
        "printf '%s\n' \"$1\" >> trash.log",
        "trash-test",
      },
    })
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    sidebar.open("files")
    t.trigger_visual_mapping(t.line_by_name("alpha.txt"), t.line_by_name("beta.txt"), "d")

    local trash_log = t.read_file(path.join(root, "trash.log"))

    t.assert_contains(trash_log, path.join(root, "alpha.txt"))
    t.assert_contains(trash_log, path.join(root, "beta.txt"))
  end)
end)

t.test("files trash mapping sends directory paths to configured command", function()
  t.temp_dir("files-trash-dir", function(root)
    t.reset_plugin({
      trash_cmd = {
        "sh",
        "-c",
        "printf '%s\n' \"$1\" >> trash.log",
        "trash-test",
      },
    })
    t.write_file(path.join(root, "dir-src", "child.txt"), "child")

    sidebar.open("files")
    t.trigger_normal_mapping(t.line_by_name("dir-src"), "d")

    t.assert_contains(t.read_file(path.join(root, "trash.log")), path.join(root, "dir-src"))
  end)
end)

t.run_if_direct("tests/files/trash_spec.lua")
