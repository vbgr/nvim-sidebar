local t = require("tests.helpers")

local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")
local state = require("nvim-sidebar.state")

t.test("buffers search filters by buffer name", function()
  t.temp_dir("buffers-search", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))

    sidebar.open("buffers")
    state.search.query = "alp"
    sidebar.refresh()

    local rendered = t.rendered_text()

    t.assert_contains(rendered, "alpha.txt")
    t.assert_not_contains(rendered, "beta.txt")
  end)
end)

t.run_if_direct("tests/buffers/search_spec.lua")
