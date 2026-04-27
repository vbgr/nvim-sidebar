local t = require("tests.helpers")

local actions = require("nvim-sidebar.input.actions")
local search = require("nvim-sidebar.search")
local sidebar = require("nvim-sidebar")
local sources = require("nvim-sidebar.sources")
local state = require("nvim-sidebar.state")

local function restore_after(replacements, fn)
  local originals = {}

  for _, replacement in ipairs(replacements) do
    originals[replacement] = replacement.table[replacement.key]
    replacement.table[replacement.key] = replacement.value
  end

  local ok, err = xpcall(fn, debug.traceback)

  for index = #replacements, 1, -1 do
    local replacement = replacements[index]
    replacement.table[replacement.key] = originals[replacement]
  end

  if not ok then
    error(err)
  end
end

local function current_buffer_items(items)
  state.set_items(vim.api.nvim_get_current_buf(), items)
end

t.test("actions dispatch refresh calls sidebar refresh", function()
  t.reset_plugin()

  local calls = 0

  restore_after({
    {
      table = sidebar,
      key = "refresh",
      value = function()
        calls = calls + 1
      end,
    },
  }, function()
    actions.dispatch("refresh")
  end)

  t.assert_equal(calls, 1)
end)

t.test("actions dispatch close calls sidebar close", function()
  t.reset_plugin()

  local calls = 0

  restore_after({
    {
      table = sidebar,
      key = "close",
      value = function()
        calls = calls + 1
      end,
    },
  }, function()
    actions.dispatch("close")
  end)

  t.assert_equal(calls, 1)
end)

t.test("actions dispatch search prompts and refreshes after search", function()
  t.reset_plugin()

  local prompts = 0
  local refreshes = 0

  restore_after({
    {
      table = search,
      key = "prompt",
      value = function(callback)
        prompts = prompts + 1
        callback()
      end,
    },
    {
      table = sidebar,
      key = "refresh",
      value = function()
        refreshes = refreshes + 1
      end,
    },
  }, function()
    actions.dispatch("search")
  end)

  t.assert_equal(prompts, 1)
  t.assert_equal(refreshes, 1)
end)

t.test("actions dispatch locate uses selected item source", function()
  t.reset_plugin()

  local source_name

  current_buffer_items({
    [1] = {
      source = "buffers",
    },
  })

  restore_after({
    {
      table = sidebar,
      key = "locate",
      value = function(name)
        source_name = name
      end,
    },
  }, function()
    vim.api.nvim_win_set_cursor(0, {
      1,
      0,
    })
    actions.dispatch("locate")
  end)

  t.assert_equal(source_name, "buffers")
end)

t.test("actions dispatch locate falls back to active source", function()
  t.reset_plugin()

  local source_name

  state.active_source = "files"

  restore_after({
    {
      table = sidebar,
      key = "locate",
      value = function(name)
        source_name = name
      end,
    },
  }, function()
    actions.dispatch("locate")
  end)

  t.assert_equal(source_name, "files")
end)

t.test("actions dispatch warns when action is unavailable", function()
  t.reset_plugin()

  local messages = {}

  state.active_source = "files"

  restore_after({
    {
      table = sources,
      key = "get",
      value = function()
        return {
          name = "files",
          actions = {},
        }
      end,
    },
    {
      table = vim,
      key = "notify",
      value = function(message, level)
        table.insert(messages, {
          message = message,
          level = level,
        })
      end,
    },
  }, function()
    actions.dispatch("missing_action")
  end)

  t.assert_equal(#messages, 1)
  t.assert_equal(messages[1].level, vim.log.levels.WARN)
  t.assert_contains(messages[1].message, "missing_action")
  t.assert_contains(messages[1].message, "files")
end)

t.test("actions dispatch passes ranged items to source handler", function()
  t.reset_plugin()

  local captured_item
  local captured_items

  current_buffer_items({
    [1] = {
      name = "alpha",
      source = "files",
    },
    [2] = {
      name = "beta",
      source = "files",
    },
    [3] = {
      name = "gamma",
      source = "files",
    },
  })

  restore_after({
    {
      table = sources,
      key = "get",
      value = function()
        return {
          name = "files",
          actions = {
            copy = function(item, ctx)
              captured_item = item
              captured_items = ctx.items
            end,
          },
        }
      end,
    },
  }, function()
    actions.dispatch("copy", {
      range = {
        start_line = 1,
        end_line = 2,
      },
    })
  end)

  t.assert_equal(captured_item.name, "alpha")
  t.assert_equal(#captured_items, 2)
  t.assert_equal(captured_items[2].name, "beta")
end)

t.test("actions dispatch passes visual selected items to source handler", function()
  t.reset_plugin()

  local captured_items

  restore_after({
    {
      table = state,
      key = "get_selected_items",
      value = function()
        return {
          {
            name = "visual-alpha",
            source = "files",
          },
          {
            name = "visual-beta",
            source = "files",
          },
        }
      end,
    },
    {
      table = sources,
      key = "get",
      value = function()
        return {
          name = "files",
          actions = {
            cut = function(_, ctx)
              captured_items = ctx.items
            end,
          },
        }
      end,
    },
  }, function()
    actions.dispatch("cut", {
      visual = true,
    })
  end)

  t.assert_equal(#captured_items, 2)
  t.assert_equal(captured_items[1].name, "visual-alpha")
  t.assert_equal(captured_items[2].name, "visual-beta")
end)

t.test("actions dispatch handler refresh callback refreshes sidebar", function()
  t.reset_plugin()

  local refreshes = 0

  current_buffer_items({
    [1] = {
      source = "files",
    },
  })

  restore_after({
    {
      table = sources,
      key = "get",
      value = function()
        return {
          name = "files",
          actions = {
            duplicate = function(_, ctx)
              ctx.refresh()
            end,
          },
        }
      end,
    },
    {
      table = sidebar,
      key = "refresh",
      value = function()
        refreshes = refreshes + 1
      end,
    },
  }, function()
    actions.dispatch("duplicate", {
      range = {
        start_line = 1,
        end_line = 1,
      },
    })
  end)

  t.assert_equal(refreshes, 1)
end)

t.run_if_direct("tests/unit/actions_spec.lua")
