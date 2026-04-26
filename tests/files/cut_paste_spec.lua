local t = require("tests.helpers")

local files = require("nvim-sidebar.sources.files")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")
local state = require("nvim-sidebar.state")

t.test("files visual cut and paste moves all selected files", function()
  t.temp_dir("files-cut-paste", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")
    vim.fn.mkdir(path.join(root, "target"), "p")

    sidebar.open("files")
    t.trigger_visual_mapping(t.line_by_name("alpha.txt"), t.line_by_name("beta.txt"), "x")

    t.assert_equal(state.fstree.clipboard.mode, "cut")
    t.assert_equal(#state.fstree.clipboard.paths, 2)

    files.actions.paste(t.item_by_name("target"), {
      refresh = sidebar.refresh,
    })

    t.assert_file_missing(path.join(root, "alpha.txt"))
    t.assert_file_missing(path.join(root, "beta.txt"))
    t.assert_file_exists(path.join(root, "target", "alpha.txt"))
    t.assert_file_exists(path.join(root, "target", "beta.txt"))
    t.assert_equal(state.fstree.clipboard.mode, nil)
    t.assert_equal(#state.fstree.clipboard.paths, 0)
  end)
end)

t.test("files cut and paste moves directories recursively", function()
  t.temp_dir("files-cut-paste-dir", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "dir-src", "child.txt"), "child")
    vim.fn.mkdir(path.join(root, "target"), "p")

    sidebar.open("files")
    t.trigger_normal_mapping(t.line_by_name("dir-src"), "x")
    files.actions.paste(t.item_by_name("target"), {
      refresh = sidebar.refresh,
    })

    t.assert_file_missing(path.join(root, "dir-src"))
    t.assert_file_exists(path.join(root, "target", "dir-src", "child.txt"))
  end)
end)

t.run_if_direct("tests/files/cut_paste_spec.lua")
