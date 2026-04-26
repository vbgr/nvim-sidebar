local t = require("tests.helpers")

local files = require("nvim-sidebar.sources.files")
local git = require("nvim-sidebar.fstree.git")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")

t.test("files view marks open buffers and git statuses", function()
  t.temp_dir("files-git", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "tracked.txt"), "tracked")
    t.write_file(path.join(root, "added.txt"), "added")
    t.write_file(path.join(root, "untracked.txt"), "untracked")

    vim.fn.system({
      "git",
      "init",
      root,
    })
    vim.fn.system({
      "git",
      "-C",
      root,
      "config",
      "user.email",
      "test@example.com",
    })
    vim.fn.system({
      "git",
      "-C",
      root,
      "config",
      "user.name",
      "nvim-sidebar tests",
    })
    vim.fn.system({
      "git",
      "-C",
      root,
      "add",
      "tracked.txt",
    })
    vim.fn.system({
      "git",
      "-C",
      root,
      "commit",
      "-m",
      "init",
    })
    t.write_file(path.join(root, "tracked.txt"), "changed")
    vim.fn.system({
      "git",
      "-C",
      root,
      "add",
      "added.txt",
    })

    local status = git.status(root)

    t.assert_equal(git.for_path(status, path.join(root, "tracked.txt")), "modified")
    t.assert_equal(git.for_path(status, path.join(root, "added.txt")), "added")
    t.assert_equal(git.for_path(status, path.join(root, "untracked.txt")), "untracked")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "tracked.txt")))
    sidebar.open("files")
    t.assert_contains(select(2, t.find_line("tracked.txt")), " o")

    local result = files.render({
      mode = "sidebar",
    })
    local markers = {}

    for _, highlight in ipairs(result.highlights) do
      if highlight.virt_text ~= nil then
        markers[highlight.virt_text] = true
      end
    end

    t.assert_true(markers.M)
    t.assert_true(markers.A)
    t.assert_true(markers["?"])
  end)
end)

t.run_if_direct("tests/files/git_spec.lua")
