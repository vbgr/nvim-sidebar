local t = require("tests.helpers")

local buffers = require("nvim-sidebar.sources.buffers")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")

t.test("buffers view renders listed buffers and modified markers", function()
  t.temp_dir("buffers-open", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    vim.api.nvim_buf_set_lines(0, 0, 0, false, {
      "changed",
    })

    sidebar.open("buffers")

    local rendered = t.rendered_text()

    t.assert_contains(rendered, tostring(alpha_bufnr))
    t.assert_contains(rendered, "alpha.txt")
    t.assert_contains(rendered, "beta.txt")
    t.assert_contains(rendered, "* beta.txt")
    t.assert_equal(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:."), "buffers")
    t.assert_false(t.has_highlight_group(buffers.render(), "NvimSidebarCurrent"))
  end)
end)

t.test("buffers open action switches previous window to selected buffer", function()
  t.temp_dir("buffers-open-action", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))

    sidebar.open("buffers")
    buffers.actions.open(t.item_by_name("alpha.txt"))

    t.assert_equal(vim.api.nvim_get_current_buf(), alpha_bufnr)
  end)
end)

t.run_if_direct("tests/buffers/open_spec.lua")
