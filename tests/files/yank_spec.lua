local t = require("tests.helpers")

local sidebar = require("nvim-sidebar")

t.test("files visual yank name mapping copies all selected file names", function()
  t.temp_dir("files-yank-name", function(root)
    t.open_fixture_tree(root)
    sidebar.open("files")

    t.trigger_visual_mapping(t.line_by_name("alpha.txt"), t.line_by_name("zeta.txt"), "y")

    t.assert_equal(vim.fn.getreg('"'), "alpha.txt\nzeta.txt")
  end)
end)

t.test("files visual yank path mapping copies all selected relative paths", function()
  t.temp_dir("files-yank-path", function(root)
    t.open_fixture_tree(root)
    sidebar.open("files")

    t.trigger_visual_mapping(t.line_by_name("alpha.txt"), t.line_by_name("zeta.txt"), "Y")

    t.assert_equal(vim.fn.getreg('"'), "alpha.txt\nzeta.txt")
  end)
end)

t.run_if_direct("tests/files/yank_spec.lua")
