local t = require("tests.helpers")

local sidebar = require("nvim-sidebar")

local function with_sidebar_stubs(stubs, fn)
  local originals = {}

  for name, stub in pairs(stubs) do
    originals[name] = sidebar[name]
    sidebar[name] = stub
  end

  local ok, err = xpcall(fn, debug.traceback)

  for name, original in pairs(originals) do
    sidebar[name] = original
  end

  if not ok then
    error(err)
  end
end

t.test("setup registers documented user commands", function()
  t.reset_plugin()

  local commands = vim.api.nvim_get_commands({})

  t.assert_true(commands.NvimSidebar ~= nil)
  t.assert_true(commands.NvimSidebarToggle ~= nil)
  t.assert_true(commands.NvimSidebarRefresh ~= nil)
  t.assert_true(commands.NvimSidebarLocate ~= nil)
  t.assert_true(commands.NvimSidebarTree ~= nil)
  t.assert_equal(commands.NvimSidebar.nargs, "?")
  t.assert_equal(commands.NvimSidebarToggle.nargs, "?")
  t.assert_equal(commands.NvimSidebarLocate.nargs, "?")
end)

t.test("commands route optional source arguments to public API", function()
  t.reset_plugin()

  local calls = {}

  with_sidebar_stubs({
    open = function(source)
      table.insert(calls, {
        name = "open",
        source = source,
      })
    end,
    toggle = function(source)
      table.insert(calls, {
        name = "toggle",
        source = source,
      })
    end,
    locate = function(source)
      table.insert(calls, {
        name = "locate",
        source = source,
      })
    end,
  }, function()
    vim.cmd("NvimSidebar files")
    vim.cmd("NvimSidebar")
    vim.cmd("NvimSidebarToggle buffers")
    vim.cmd("NvimSidebarToggle")
    vim.cmd("NvimSidebarLocate files")
    vim.cmd("NvimSidebarLocate")
  end)

  t.assert_equal(calls[1].name, "open")
  t.assert_equal(calls[1].source, "files")
  t.assert_equal(calls[2].name, "open")
  t.assert_equal(calls[2].source, nil)
  t.assert_equal(calls[3].name, "toggle")
  t.assert_equal(calls[3].source, "buffers")
  t.assert_equal(calls[4].name, "toggle")
  t.assert_equal(calls[4].source, nil)
  t.assert_equal(calls[5].name, "locate")
  t.assert_equal(calls[5].source, "files")
  t.assert_equal(calls[6].name, "locate")
  t.assert_equal(calls[6].source, nil)
end)

t.test("commands route refresh and full tree commands to public API", function()
  t.reset_plugin()

  local calls = {}

  with_sidebar_stubs({
    refresh = function()
      table.insert(calls, "refresh")
    end,
    open_full_tree = function()
      table.insert(calls, "open_full_tree")
    end,
  }, function()
    vim.cmd("NvimSidebarRefresh")
    vim.cmd("NvimSidebarTree")
  end)

  t.assert_equal(calls[1], "refresh")
  t.assert_equal(calls[2], "open_full_tree")
end)

t.test("commands complete configured source names", function()
  t.reset_plugin()

  local completions = vim.fn.getcompletion("NvimSidebar ", "cmdline")

  t.assert_true(vim.tbl_contains(completions, "files"))
  t.assert_true(vim.tbl_contains(completions, "buffers"))
end)

t.run_if_direct("tests/unit/commands_spec.lua")
