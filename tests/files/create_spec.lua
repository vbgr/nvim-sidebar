local t = require("tests.helpers")

local fs_ops = require("nvim-sidebar.fstree.fs_ops")
local path = require("nvim-sidebar.util.path")
require("nvim-sidebar")

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

t.test("files new file and new directory create entries under selected directory", function()
  t.temp_dir("files-create", function(root)
    t.reset_plugin()

    local prompts = {
      "created.txt",
      "created-dir",
    }
    local root_item = {
      kind = "directory",
      path = root,
    }

    with_inputs(prompts, function()
      fs_ops.new_file(root_item)
      fs_ops.new_directory(root_item)
    end)

    t.assert_file_exists(path.join(root, "created.txt"))
    t.assert_file_exists(path.join(root, "created-dir"))
  end)
end)

t.test("files new file creates under cwd when no item is selected", function()
  t.temp_dir("files-create-cwd", function(root)
    t.reset_plugin()

    local refreshes = 0

    with_inputs({ "created-at-cwd.txt" }, function()
      fs_ops.new_file(nil, function()
        refreshes = refreshes + 1
      end)
    end)

    t.assert_file_exists(path.join(root, "created-at-cwd.txt"))
    t.assert_equal(refreshes, 1)
  end)
end)

t.test("files new directory creates beside selected file", function()
  t.temp_dir("files-create-beside-file", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "parent", "source.txt"), "source")

    local refreshes = 0

    with_inputs({ "sibling-dir" }, function()
      fs_ops.new_directory({
        kind = "file",
        path = path.join(root, "parent", "source.txt"),
      }, function()
        refreshes = refreshes + 1
      end)
    end)

    t.assert_file_exists(path.join(root, "parent", "sibling-dir"))
    t.assert_equal(refreshes, 1)
  end)
end)

t.test("files create prompt cancellation does not refresh", function()
  t.temp_dir("files-create-cancel", function(root)
    t.reset_plugin()

    local refreshes = 0

    with_inputs({ "" }, function()
      fs_ops.new_file({
        kind = "directory",
        path = root,
      }, function()
        refreshes = refreshes + 1
      end)
    end)

    t.assert_equal(refreshes, 0)
  end)
end)

t.test("files new file reports existing target without overwriting", function()
  t.temp_dir("files-create-existing", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "existing.txt"), "original")

    local refreshes = 0
    local messages = capture_notify(function()
      with_inputs({ "existing.txt" }, function()
        fs_ops.new_file({
          kind = "directory",
          path = root,
        }, function()
          refreshes = refreshes + 1
        end)
      end)
    end)

    t.assert_equal(t.read_file(path.join(root, "existing.txt")), "original")
    t.assert_equal(refreshes, 0)
    t.assert_equal(#messages, 1)
    t.assert_equal(messages[1].level, vim.log.levels.WARN)
    t.assert_contains(messages[1].message, "File already exists")
  end)
end)

t.run_if_direct("tests/files/create_spec.lua")
