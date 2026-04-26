local t = require("tests.helpers")

local expand = require("nvim-sidebar.fstree.expand")
local files = require("nvim-sidebar.sources.files")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")

t.test("files view renders cwd path, directories first, and directory highlights", function()
  t.temp_dir("files-open", function(root)
    t.open_fixture_tree(root)

    sidebar.open("files")

    local dir_a_line = t.line_by_name("dir-a")
    local dir_b_line = t.line_by_name("dir-b")
    local alpha_line = t.line_by_name("alpha.txt")
    local zeta_line = t.line_by_name("zeta.txt")

    t.assert_equal(
      vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:."),
      vim.fn.fnamemodify(root, ":~")
    )
    t.assert_true(dir_a_line < alpha_line)
    t.assert_true(dir_b_line < alpha_line)
    t.assert_true(alpha_line < zeta_line)
    t.assert_true(t.has_highlight_group(
      files.render({
        mode = "sidebar",
      }),
      "NvimSidebarDirectory"
    ))
  end)
end)

t.test("files view marks files opened in buffers", function()
  t.temp_dir("files-open-buffer-marker", function(root)
    t.open_fixture_tree(root)
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))

    sidebar.open("files")

    t.assert_contains(select(2, t.find_line("alpha.txt")), " o")
  end)
end)

t.test("files view does not render excluded entries", function()
  t.temp_dir("files-open-exclusions", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, ".DS_Store"), "metadata")
    t.write_file(path.join(root, "module.pyc"), "bytecode")
    vim.fn.mkdir(path.join(root, "__pycache__"), "p")
    vim.fn.mkdir(path.join(root, "node_modules"), "p")
    t.write_file(path.join(root, "visible.txt"), "visible")

    sidebar.open("files")

    local rendered = t.rendered_text()

    t.assert_contains(rendered, "visible.txt")
    t.assert_not_contains(rendered, ".DS_Store")
    t.assert_not_contains(rendered, "module.pyc")
    t.assert_not_contains(rendered, "__pycache__")
    t.assert_not_contains(rendered, "node_modules")
  end)
end)

t.test("files open action expands directories and opens files in previous window", function()
  t.temp_dir("files-open-action", function(root)
    t.open_fixture_tree(root)

    sidebar.open("files")
    files.actions.open(t.item_by_name("dir-b"), {
      refresh = sidebar.refresh,
    })

    t.assert_true(expand.is_expanded(path.join(root, "dir-b")))

    files.actions.open(t.item_by_name("child.txt"), {
      refresh = sidebar.refresh,
    })

    t.assert_equal(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"), "child.txt")
  end)
end)

t.run_if_direct("tests/files/open_spec.lua")
