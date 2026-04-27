local t = require("tests.helpers")

local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")
local state = require("nvim-sidebar.state")

t.test("buffers locate positions cursor on current editor buffer", function()
  t.temp_dir("buffers-locate", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))

    sidebar.locate("buffers")

    t.assert_equal(vim.bo.filetype, "nvim-sidebar")
    t.assert_equal(state.get_current_item().name, "beta.txt")
  end)
end)

t.run_if_direct("tests/buffers/locate_spec.lua")
