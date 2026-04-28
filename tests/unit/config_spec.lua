local t = require("tests.helpers")

local config = require("nvim-sidebar.config")

t.test("config merges user options", function()
  local options = config.setup({
    width = 42,
    side = "right",
    padding_left = 4,
    default_source = "buffers",
    sources = {
      "buffers",
    },
    keymaps = {
      copy = "<leader>c",
    },
    tree = {
      full_columns = {
        "type",
        "size",
      },
    },
  })

  t.assert_equal(options.width, 42)
  t.assert_equal(options.side, "right")
  t.assert_equal(options.padding_left, 4)
  t.assert_equal(options.default_source, "buffers")
  t.assert_equal(options.sources[1], "buffers")
  t.assert_equal(options.keymaps.copy, "<leader>c")
  t.assert_equal(options.keymaps.open_and_close, "<CR>")
  t.assert_equal(options.keymaps.clear_search, "<Esc>")
  t.assert_equal(options.keymaps.next_buffer, "<Tab>")
  t.assert_equal(options.keymaps.previous_buffer, "<S-Tab>")
  t.assert_equal(options.tree.full_columns[1], "type")
  t.assert_equal(options.tree.full_columns[2], "size")
  t.assert_equal(options.tree.exclude_patterns[1], "^%.git$")
end)

t.test("config rejects invalid values", function()
  t.assert_false(pcall(config.setup, {
    side = "middle",
  }))
  t.assert_false(pcall(config.setup, {
    width = 0,
  }))
  t.assert_false(pcall(config.setup, {
    padding_left = -1,
  }))
  t.assert_false(pcall(config.setup, {
    sources = {
      "unknown",
    },
  }))
  t.assert_false(pcall(config.setup, {
    tree = {
      exclude_patterns = "node_modules",
    },
  }))
  t.assert_false(pcall(config.setup, {
    tree = {
      exclude_patterns = {
        1,
      },
    },
  }))
  t.assert_false(pcall(config.setup, {
    tree = {
      exclude_patterns = {
        "[",
      },
    },
  }))
  t.assert_false(pcall(config.setup, {
    tree = {
      exclude_patterns = {
        custom = "^dist$",
      },
    },
  }))
end)

t.test("config exposes reasonable default exclude patterns", function()
  local options = config.setup()
  local patterns = table.concat(options.tree.exclude_patterns, "\n")

  t.assert_contains(patterns, "^%.git$")
  t.assert_contains(patterns, "^%.DS_Store$")
  t.assert_contains(patterns, "%.pyc$")
  t.assert_contains(patterns, "^__pycache__$")
  t.assert_contains(patterns, "^node_modules$")
end)

t.test("config accepts custom exclude patterns", function()
  local options = config.setup({
    tree = {
      exclude_patterns = {
        "^dist$",
        "%.log$",
      },
    },
  })

  t.assert_equal(#options.tree.exclude_patterns, 2)
  t.assert_equal(options.tree.exclude_patterns[1], "^dist$")
  t.assert_equal(options.tree.exclude_patterns[2], "%.log$")
end)

t.run_if_direct("tests/unit/config_spec.lua")
