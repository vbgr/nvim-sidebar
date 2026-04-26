local t = require("tests.helpers")

local fs_ops = require("nvim-sidebar.fstree.fs_ops")
local path = require("nvim-sidebar.util.path")

t.test("files new file and new directory create entries under selected directory", function()
  t.temp_dir("files-create", function(root)
    t.reset_plugin()

    local prompts = {
      "created.txt",
      "created-dir",
    }
    local original_input = vim.ui.input

    vim.ui.input = function(_, callback)
      callback(table.remove(prompts, 1))
    end

    local root_item = {
      kind = "directory",
      path = root,
    }

    fs_ops.new_file(root_item)
    fs_ops.new_directory(root_item)
    vim.ui.input = original_input

    t.assert_file_exists(path.join(root, "created.txt"))
    t.assert_file_exists(path.join(root, "created-dir"))
  end)
end)

t.run_if_direct("tests/files/create_spec.lua")
