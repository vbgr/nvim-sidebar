local t = require("tests.helpers")

local config = require("nvim-sidebar.config")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")

local function display_end(line, text)
  local _, end_col = line:find(text, 1, true)

  if end_col == nil then
    return nil
  end

  return vim.fn.strdisplaywidth(line:sub(1, end_col))
end

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
    local directory_size = config.options.tree.directory_size

    t.assert_contains(rendered, "Folder")
    t.assert_contains(rendered, directory_size)
    t.assert_contains(rendered, "md")
    t.assert_contains(rendered, "12B")
    t.assert_equal(
      vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:."),
      vim.fn.fnamemodify(root, ":~")
    )

    local dir_line = select(2, t.find_line("docs"))
    local file_line = select(2, t.find_line("README.md"))
    local directory_size_end = display_end(dir_line, directory_size)
    local size_end = display_end(file_line, "12B")

    t.assert_equal(size_end, directory_size_end)
  end)
end)

t.test("full tree disables listchars in its window", function()
  t.temp_dir("files-full-tree-listchars", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "README.md"), "hello world")
    vim.wo.list = true

    sidebar.open_full_tree()

    t.assert_false(vim.wo.list)
  end)
end)

t.test("full tree uses cwd path as local statusline title", function()
  t.temp_dir("files-full-tree-title", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "README.md"), "hello world")

    sidebar.open_full_tree()

    t.assert_equal(vim.wo.statusline, " " .. vim.fn.fnamemodify(root, ":~"))
  end)
end)

t.run_if_direct("tests/files/full_tree_spec.lua")
