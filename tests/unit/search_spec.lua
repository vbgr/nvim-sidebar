local t = require("tests.helpers")

local search = require("nvim-sidebar.search")
local state = require("nvim-sidebar.state")

local function with_input(input, fn)
  local original_input = vim.ui.input

  vim.ui.input = function(opts, callback)
    callback(input)
  end

  local ok, err = xpcall(fn, debug.traceback)

  vim.ui.input = original_input

  if not ok then
    error(err)
  end
end

t.test("search prompt leaves query unchanged when input is cancelled", function()
  t.reset_plugin()
  state.search.query = "existing"

  local calls = 0

  with_input(nil, function()
    search.prompt(function()
      calls = calls + 1
    end)
  end)

  t.assert_equal(state.search.query, "existing")
  t.assert_equal(calls, 0)
end)

t.test("search prompt stores input and runs callback", function()
  t.reset_plugin()
  state.search.query = "old"

  local calls = 0

  with_input("new", function()
    search.prompt(function()
      calls = calls + 1
    end)
  end)

  t.assert_equal(state.search.query, "new")
  t.assert_equal(calls, 1)
end)

t.run_if_direct("tests/unit/search_spec.lua")
