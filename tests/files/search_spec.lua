local t = require("tests.helpers")

local files = require("nvim-sidebar.sources.files")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")
local state = require("nvim-sidebar.state")

t.test("files search filters visible entries only", function()
  t.temp_dir("files-search", function(root)
    t.open_fixture_tree(root)

    sidebar.open("files")
    state.search.query = "deep"
    sidebar.refresh()

    t.assert_not_contains(t.item_names(), "deep.md")

    state.search.query = ""
    sidebar.refresh()
    files.actions.open(t.item_by_name("dir-a"), {
      refresh = sidebar.refresh,
    })
    files.actions.open(t.item_by_name("nested"), {
      refresh = sidebar.refresh,
    })
    state.search.query = "deep"
    sidebar.refresh()

    t.assert_contains(t.item_names(), "deep.md")
  end)
end)

t.test("files search does not reveal excluded entries", function()
  t.temp_dir("files-search-exclusions", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "module.pyc"), "bytecode")
    t.write_file(path.join(root, "visible.txt"), "visible")

    sidebar.open("files")
    state.search.query = "module"
    sidebar.refresh()

    t.assert_not_contains(t.rendered_text(), "module.pyc")
    t.assert_not_contains(t.item_names(), "module.pyc")
  end)
end)

t.run_if_direct("tests/files/search_spec.lua")
