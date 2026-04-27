local t = require("tests.helpers")

local fs_ops = require("nvim-sidebar.fstree.fs_ops")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")

local function capture_notify(fn)
  local notify = vim.notify
  local messages = {}

  vim.notify = function(message, level)
    table.insert(messages, {
      message = message,
      level = level,
    })
  end

  local ok, err = xpcall(fn, debug.traceback)

  vim.notify = notify

  if not ok then
    error(err)
  end

  return messages
end

t.test("files duplicate creates a file copy next to original", function()
  t.temp_dir("files-duplicate-file", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "dup.txt"), "dup")

    fs_ops.duplicate({
      {
        path = path.join(root, "dup.txt"),
      },
    })

    t.assert_file_exists(path.join(root, "dup.txt copy"))
  end)
end)

t.test("files duplicate creates numbered copy when copy already exists", function()
  t.temp_dir("files-duplicate-numbered", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "dup"), "dup")
    t.write_file(path.join(root, "dup copy"), "existing")

    fs_ops.duplicate({
      {
        path = path.join(root, "dup"),
      },
    })

    t.assert_file_exists(path.join(root, "dup copy 2"))
  end)
end)

t.test("files duplicate reports missing source", function()
  t.temp_dir("files-duplicate-missing", function(root)
    t.reset_plugin()

    local messages = capture_notify(function()
      fs_ops.duplicate({
        {
          path = path.join(root, "missing.txt"),
        },
      })
    end)

    t.assert_equal(#messages, 1)
    t.assert_equal(messages[1].level, vim.log.levels.ERROR)
    t.assert_contains(messages[1].message, "source does not exist")
  end)
end)

t.test("files duplicate recursively copies directories next to original", function()
  t.temp_dir("files-duplicate-dir", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "dir-src", "child.txt"), "child")

    fs_ops.duplicate({
      {
        path = path.join(root, "dir-src"),
      },
    })

    t.assert_file_exists(path.join(root, "dir-src copy", "child.txt"))
  end)
end)

t.test("files visual duplicate duplicates all selected files", function()
  t.temp_dir("files-duplicate-visual", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    sidebar.open("files")
    t.trigger_visual_mapping(t.line_by_name("alpha.txt"), t.line_by_name("beta.txt"), "D")

    t.assert_file_exists(path.join(root, "alpha.txt copy"))
    t.assert_file_exists(path.join(root, "beta.txt copy"))
  end)
end)

t.run_if_direct("tests/files/duplicate_spec.lua")
