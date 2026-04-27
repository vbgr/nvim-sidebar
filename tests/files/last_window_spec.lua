local t = require("tests.helpers")

local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")
local window = require("nvim-sidebar.ui.window")

t.test("sidebar closes before it becomes the last window", function()
  t.temp_dir("files-last-window", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "file.txt"), "file")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "file.txt")))
    sidebar.open("files")
    vim.cmd.wincmd("p")

    window.close_sidebar_if_last_regular_window()

    t.assert_false(window.is_sidebar_open())
    t.assert_equal(#vim.api.nvim_tabpage_list_wins(0), 1)
  end)
end)

t.run_if_direct("tests/files/last_window_spec.lua")
