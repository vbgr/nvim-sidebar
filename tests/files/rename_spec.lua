local t = require("tests.helpers")

local files = require("nvim-sidebar.sources.files")
local fs_ops = require("nvim-sidebar.fstree.fs_ops")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")
local state = require("nvim-sidebar.state")

local function with_inputs(prompts, fn)
  local original_input = vim.ui.input

  vim.ui.input = function(_, callback)
    callback(table.remove(prompts, 1))
  end

  local ok, err = xpcall(fn, debug.traceback)

  vim.ui.input = original_input

  if not ok then
    error(err)
  end
end

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

t.test("files rename renames file beside itself", function()
  t.temp_dir("files-rename-file", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "old.txt"), "old")

    local refreshes = 0
    local restored_path

    with_inputs({ "new.txt" }, function()
      fs_ops.rename({
        kind = "file",
        name = "old.txt",
        path = path.join(root, "old.txt"),
      }, function(target)
        refreshes = refreshes + 1
        restored_path = target
      end)
    end)

    t.assert_file_missing(path.join(root, "old.txt"))
    t.assert_equal(t.read_file(path.join(root, "new.txt")), "old")
    t.assert_equal(refreshes, 1)
    t.assert_equal(restored_path, path.join(root, "new.txt"))
  end)
end)

t.test("files rename action renames directory and restores cursor", function()
  t.temp_dir("files-rename-directory", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "old-dir", "child.txt"), "child")

    sidebar.open("files")

    with_inputs({ "new-dir" }, function()
      files.actions.rename(t.item_by_name("old-dir"), {
        refresh = sidebar.refresh,
      })
    end)

    t.assert_file_missing(path.join(root, "old-dir"))
    t.assert_file_exists(path.join(root, "new-dir", "child.txt"))
    t.assert_equal(state.get_current_item().name, "new-dir")
  end)
end)

t.test("files rename prompt cancellation does not refresh", function()
  t.temp_dir("files-rename-cancel", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "old.txt"), "old")

    local refreshes = 0

    with_inputs({ "" }, function()
      fs_ops.rename({
        kind = "file",
        name = "old.txt",
        path = path.join(root, "old.txt"),
      }, function()
        refreshes = refreshes + 1
      end)
    end)

    t.assert_file_exists(path.join(root, "old.txt"))
    t.assert_equal(refreshes, 0)
  end)
end)

t.test("files rename reports existing target without overwriting", function()
  t.temp_dir("files-rename-existing", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "old.txt"), "old")
    t.write_file(path.join(root, "existing.txt"), "existing")

    local refreshes = 0
    local messages = capture_notify(function()
      with_inputs({ "existing.txt" }, function()
        fs_ops.rename({
          kind = "file",
          name = "old.txt",
          path = path.join(root, "old.txt"),
        }, function()
          refreshes = refreshes + 1
        end)
      end)
    end)

    t.assert_equal(t.read_file(path.join(root, "old.txt")), "old")
    t.assert_equal(t.read_file(path.join(root, "existing.txt")), "existing")
    t.assert_equal(refreshes, 0)
    t.assert_equal(#messages, 1)
    t.assert_equal(messages[1].level, vim.log.levels.WARN)
    t.assert_contains(messages[1].message, "File already exists")
  end)
end)

t.run_if_direct("tests/files/rename_spec.lua")
