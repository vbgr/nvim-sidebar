local t = require("tests.helpers")

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

t.test("files visual trash mapping sends all selected paths to configured command", function()
  t.temp_dir("files-trash", function(root)
    t.reset_plugin({
      trash_cmd = {
        "sh",
        "-c",
        "printf '%s\n' \"$1\" >> trash.log",
        "trash-test",
      },
    })
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    sidebar.open("files")
    t.trigger_visual_mapping(t.line_by_name("alpha.txt"), t.line_by_name("beta.txt"), "d")

    local trash_log = t.read_file(path.join(root, "trash.log"))

    t.assert_contains(trash_log, path.join(root, "alpha.txt"))
    t.assert_contains(trash_log, path.join(root, "beta.txt"))
  end)
end)

t.test("files trash mapping sends directory paths to configured command", function()
  t.temp_dir("files-trash-dir", function(root)
    t.reset_plugin({
      trash_cmd = {
        "sh",
        "-c",
        "printf '%s\n' \"$1\" >> trash.log",
        "trash-test",
      },
    })
    t.write_file(path.join(root, "dir-src", "child.txt"), "child")

    sidebar.open("files")
    t.trigger_normal_mapping(t.line_by_name("dir-src"), "d")

    t.assert_contains(t.read_file(path.join(root, "trash.log")), path.join(root, "dir-src"))
  end)
end)

t.test("files trash removes last file from directory and refreshes empty state", function()
  t.temp_dir("files-trash-last-file", function(root)
    t.reset_plugin({
      trash_cmd = {
        "sh",
        "-c",
        'rm -f "$1"',
        "trash-test",
      },
    })
    t.write_file(path.join(root, "alpha.txt"), "alpha")

    sidebar.open("files")
    t.trigger_normal_mapping(t.line_by_name("alpha.txt"), "d")

    t.assert_file_missing(path.join(root, "alpha.txt"))
    t.assert_equal(t.rendered_text(), "No files")
  end)
end)

t.test("files trash reports missing configured command at operation time", function()
  t.temp_dir("files-trash-missing-command", function(root)
    local messages = capture_notify(function()
      t.reset_plugin({
        trash_cmd = {
          "nvim-sidebar-missing-trash-command",
        },
      })
      t.write_file(path.join(root, "alpha.txt"), "alpha")

      sidebar.open("files")
      t.trigger_normal_mapping(t.line_by_name("alpha.txt"), "d")
    end)

    t.assert_file_exists(path.join(root, "alpha.txt"))
    t.assert_equal(#messages, 1)
    t.assert_equal(messages[1].level, vim.log.levels.ERROR)
    t.assert_contains(messages[1].message, "trash_cmd is not executable")
  end)
end)

t.test("files trash reports missing trash_cmd configuration", function()
  t.temp_dir("files-trash-no-command", function(root)
    local messages = capture_notify(function()
      t.reset_plugin()
      t.write_file(path.join(root, "alpha.txt"), "alpha")

      sidebar.open("files")
      t.trigger_normal_mapping(t.line_by_name("alpha.txt"), "d")
    end)

    t.assert_file_exists(path.join(root, "alpha.txt"))
    t.assert_equal(#messages, 1)
    t.assert_equal(messages[1].level, vim.log.levels.WARN)
    t.assert_contains(messages[1].message, "trash_cmd is not configured")
  end)
end)

t.test("files trash reports command failure", function()
  t.temp_dir("files-trash-command-failure", function(root)
    local messages = capture_notify(function()
      t.reset_plugin({
        trash_cmd = {
          "sh",
          "-c",
          "echo failed; exit 1",
          "trash-test",
        },
      })
      t.write_file(path.join(root, "alpha.txt"), "alpha")

      sidebar.open("files")
      t.trigger_normal_mapping(t.line_by_name("alpha.txt"), "d")
    end)

    t.assert_file_exists(path.join(root, "alpha.txt"))
    t.assert_equal(#messages, 1)
    t.assert_equal(messages[1].level, vim.log.levels.ERROR)
    t.assert_contains(messages[1].message, "failed")
  end)
end)

t.run_if_direct("tests/files/trash_spec.lua")
