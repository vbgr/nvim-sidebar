local t = require("tests.helpers")

local expand = require("nvim-sidebar.fstree.expand")
local files = require("nvim-sidebar.sources.files")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")
local state = require("nvim-sidebar.state")

t.test("files collapse on a child collapses parent and moves cursor to parent", function()
  t.temp_dir("files-toggle-collapse", function(root)
    t.open_fixture_tree(root)

    sidebar.open("files")
    files.actions.open(t.item_by_name("dir-b"), {
      refresh = sidebar.refresh,
    })
    files.actions.collapse(t.item_by_name("child.txt"), {
      refresh = sidebar.refresh,
    })

    t.assert_false(expand.is_expanded(path.join(root, "dir-b")))
    t.assert_equal(state.get_current_item().name, "dir-b")
  end)
end)

t.test("files expansion state is preserved while sidebar is closed", function()
  t.temp_dir("files-toggle-preserve", function(root)
    t.open_fixture_tree(root)

    sidebar.open("files")
    files.actions.open(t.item_by_name("dir-a"), {
      refresh = sidebar.refresh,
    })
    sidebar.close()
    sidebar.open("files")

    t.assert_true(expand.is_expanded(path.join(root, "dir-a")))
    t.assert_contains(t.item_names(), "nested")
  end)
end)

t.run_if_direct("tests/files/toggle_spec.lua")
