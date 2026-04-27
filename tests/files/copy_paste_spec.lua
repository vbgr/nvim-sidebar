local t = require("tests.helpers")

local fs_ops = require("nvim-sidebar.fstree.fs_ops")
local files = require("nvim-sidebar.sources.files")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")
local state = require("nvim-sidebar.state")

t.test("files visual copy and paste copies all selected files", function()
  t.temp_dir("files-copy-paste", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")
    vim.fn.mkdir(path.join(root, "target"), "p")

    sidebar.open("files")
    t.trigger_visual_mapping(t.line_by_name("alpha.txt"), t.line_by_name("beta.txt"), "c")

    t.assert_equal(state.fstree.clipboard.mode, "copy")
    t.assert_equal(#state.fstree.clipboard.paths, 2)

    files.actions.paste(t.item_by_name("target"), {
      refresh = sidebar.refresh,
    })

    t.assert_file_exists(path.join(root, "alpha.txt"))
    t.assert_file_exists(path.join(root, "beta.txt"))
    t.assert_file_exists(path.join(root, "target", "alpha.txt"))
    t.assert_file_exists(path.join(root, "target", "beta.txt"))
  end)
end)

t.test("files paste without clipboard data is a no-op", function()
  t.temp_dir("files-copy-paste-empty", function(root)
    t.reset_plugin()

    local refreshes = 0

    fs_ops.paste({
      kind = "directory",
      path = root,
    }, function()
      refreshes = refreshes + 1
    end)

    t.assert_equal(refreshes, 0)
  end)
end)

t.test("files paste onto file item copies into selected file parent", function()
  t.temp_dir("files-copy-paste-onto-file", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "target", "existing.txt"), "existing")

    local refreshes = 0

    fs_ops.copy({
      {
        path = path.join(root, "alpha.txt"),
      },
    })
    fs_ops.paste({
      kind = "file",
      path = path.join(root, "target", "existing.txt"),
    }, function()
      refreshes = refreshes + 1
    end)

    t.assert_file_exists(path.join(root, "target", "alpha.txt"))
    t.assert_equal(refreshes, 1)
  end)
end)

t.test("files copy and paste recursively copies directories", function()
  t.temp_dir("files-copy-paste-dir", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "dir-src", "child.txt"), "child")
    vim.fn.mkdir(path.join(root, "target"), "p")

    sidebar.open("files")
    t.trigger_normal_mapping(t.line_by_name("dir-src"), "c")
    files.actions.paste(t.item_by_name("target"), {
      refresh = sidebar.refresh,
    })

    t.assert_file_exists(path.join(root, "dir-src", "child.txt"))
    t.assert_file_exists(path.join(root, "target", "dir-src", "child.txt"))
  end)
end)

t.run_if_direct("tests/files/copy_paste_spec.lua")
