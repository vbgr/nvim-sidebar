local t = require("tests.helpers")

local buffers = require("nvim-sidebar.sources.buffers")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")

t.test("buffers yank action copies selected buffer names", function()
  buffers.actions.yank_name(nil, {
    items = {
      {
        name = "alpha.txt",
      },
      {
        name = "beta.txt",
      },
    },
  })

  t.assert_equal(vim.fn.getreg('"'), "alpha.txt\nbeta.txt")
end)

t.test("buffers visual yank mapping copies all selected buffer names", function()
  t.temp_dir("buffers-yank", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))

    sidebar.open("buffers")

    local alpha_line = t.line_by_name("alpha.txt")
    local beta_line = t.line_by_name("beta.txt")

    t.trigger_visual_mapping(alpha_line, beta_line, "y")
    t.assert_equal(vim.fn.getreg('"'), "alpha.txt\nbeta.txt")
  end)
end)

t.run_if_direct("tests/buffers/yank_spec.lua")
