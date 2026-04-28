local t = require("tests.helpers")

local search = require("nvim-sidebar.search")
local state = require("nvim-sidebar.state")

local function with_feedkeys(fn)
  local original_feedkeys = vim.api.nvim_feedkeys
  local fed_keys = {}

  vim.api.nvim_feedkeys = function(keys, mode, escape_ks)
    table.insert(fed_keys, {
      keys = keys,
      mode = mode,
      escape_ks = escape_ks,
    })
  end

  local ok, err = xpcall(function()
    fn(fed_keys)
  end, debug.traceback)

  vim.api.nvim_feedkeys = original_feedkeys

  if not ok then
    error(err)
  end
end

t.test("search start clears query, refreshes, and opens native slash search", function()
  t.reset_plugin()
  state.search.query = "old"

  local refreshes = 0

  with_feedkeys(function(fed_keys)
    search.start(function()
      refreshes = refreshes + 1
    end)

    t.assert_equal(state.search.query, "")
    t.assert_equal(refreshes, 1)
    t.assert_equal(#fed_keys, 1)
    t.assert_equal(fed_keys[1].keys, "/")
    t.assert_equal(fed_keys[1].mode, "n")

    search.finish(true, "")
  end)
end)

t.test("search update stores live query and refreshes", function()
  t.reset_plugin()

  local refreshes = 0

  with_feedkeys(function()
    search.start(function()
      refreshes = refreshes + 1
    end)

    search.update("alpha")

    t.assert_equal(state.search.query, "alpha")
    t.assert_equal(refreshes, 2)

    search.finish(false, "alpha")
  end)
end)

t.test("search finish keeps accepted query", function()
  t.reset_plugin()

  local refreshes = 0

  with_feedkeys(function()
    search.start(function()
      refreshes = refreshes + 1
    end)

    search.update("alpha")
    search.finish(false, "alpha")

    t.assert_equal(state.search.query, "alpha")
    t.assert_equal(refreshes, 2)
  end)
end)

t.test("search finish clears aborted query", function()
  t.reset_plugin()

  local refreshes = 0

  with_feedkeys(function()
    search.start(function()
      refreshes = refreshes + 1
    end)

    search.update("alpha")
    search.finish(true, "alpha")

    t.assert_equal(state.search.query, "")
    t.assert_equal(refreshes, 3)
  end)
end)

t.test("search clear resets query and refreshes", function()
  t.reset_plugin()
  state.search.query = "alpha"

  local refreshes = 0

  search.clear(function()
    refreshes = refreshes + 1
  end)

  t.assert_equal(state.search.query, "")
  t.assert_equal(refreshes, 1)
end)

t.run_if_direct("tests/unit/search_spec.lua")
