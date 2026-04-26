local t = require("tests.helpers")

local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")

t.test("full tree renders configurable metadata columns and aligned size column", function()
  t.temp_dir("files-full-tree", function(root)
    t.reset_plugin({
      tree = {
        full_columns = {
          "type",
          "size",
          "modified",
        },
      },
    })
    t.write_file(path.join(root, "README.md"), "hello world")
    vim.fn.mkdir(path.join(root, "docs"), "p")

    sidebar.open_full_tree()

    local rendered = t.rendered_text()

    t.assert_contains(rendered, "Folder")
    t.assert_contains(rendered, "--")
    t.assert_contains(rendered, "md")
    t.assert_contains(rendered, "12B")
    t.assert_equal(
      vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:."),
      vim.fn.fnamemodify(root, ":~")
    )

    local dir_line = select(2, t.find_line("docs"))
    local file_line = select(2, t.find_line("README.md"))
    local dash_end = dir_line:find("%-%-", 1, false) + 1
    local size_end = file_line:find("12B", 1, false) + 2

    t.assert_equal(size_end, dash_end)
  end)
end)

t.run_if_direct("tests/files/full_tree_spec.lua")
