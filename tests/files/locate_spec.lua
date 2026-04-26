local t = require("tests.helpers")

local expand = require("nvim-sidebar.fstree.expand")
local files = require("nvim-sidebar.sources.files")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")
local state = require("nvim-sidebar.state")

t.test("files locate expands parents and positions cursor on current file", function()
  t.temp_dir("files-locate", function(root)
    t.open_fixture_tree(root)

    local nested_path = path.join(root, "dir-a", "nested", "deep.md")

    vim.cmd("edit " .. vim.fn.fnameescape(nested_path))
    sidebar.locate("files")

    t.assert_equal(vim.bo.filetype, "nvim-sidebar")
    t.assert_equal(state.get_current_item().path, nested_path)
    t.assert_true(expand.is_expanded(path.join(root, "dir-a")))
    t.assert_true(expand.is_expanded(path.join(root, "dir-a", "nested")))
    t.assert_false(t.has_highlight_group(
      files.render({
        mode = "sidebar",
      }),
      "NvimSidebarCurrent"
    ))
  end)
end)

t.run_if_direct("tests/files/locate_spec.lua")
