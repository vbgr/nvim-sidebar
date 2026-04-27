local t = require("tests.helpers")

local path = require("nvim-sidebar.util.path")
local scanner = require("nvim-sidebar.fstree.scanner")

t.test("scanner excludes default patterns and sorts directories before files", function()
  t.temp_dir("scanner", function(root)
    t.reset_plugin()
    vim.fn.mkdir(path.join(root, ".git"), "p")
    vim.fn.mkdir(path.join(root, "__pycache__"), "p")
    vim.fn.mkdir(path.join(root, "node_modules"), "p")
    vim.fn.mkdir(path.join(root, "z-dir"), "p")
    vim.fn.mkdir(path.join(root, "a-dir"), "p")
    t.write_file(path.join(root, ".DS_Store"), "metadata")
    t.write_file(path.join(root, "module.pyc"), "bytecode")
    t.write_file(path.join(root, "b.txt"), "b")
    t.write_file(path.join(root, "a.txt"), "a")

    local entries = scanner.scan(root)

    t.assert_equal(entries[1].name, "a-dir")
    t.assert_equal(entries[2].name, "z-dir")
    t.assert_equal(entries[3].name, "a.txt")
    t.assert_equal(entries[4].name, "b.txt")
    t.assert_equal(#entries, 4)
  end)
end)

t.test("scanner excludes custom Lua patterns", function()
  t.temp_dir("scanner-custom-patterns", function(root)
    t.reset_plugin({
      tree = {
        exclude_patterns = {
          "^dist$",
          "%.log$",
        },
      },
    })
    vim.fn.mkdir(path.join(root, "dist"), "p")
    t.write_file(path.join(root, "debug.log"), "debug")
    t.write_file(path.join(root, "keep.txt"), "keep")

    local entries = scanner.scan(root)

    t.assert_equal(#entries, 1)
    t.assert_equal(entries[1].name, "keep.txt")
  end)
end)

t.run_if_direct("tests/unit/scanner_spec.lua")
