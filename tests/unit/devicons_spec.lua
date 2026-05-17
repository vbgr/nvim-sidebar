local t = require("tests.helpers")

local config = require("nvim-sidebar.config")
local devicons = require("nvim-sidebar.integrations.devicons")

local function with_config(opts, fn)
  config.setup(opts)

  local ok, err = xpcall(fn, debug.traceback)

  config.setup()

  if not ok then
    error(err)
  end
end

local function with_fake_devicons(module, fn)
  local loaded = package.loaded["nvim-web-devicons"]
  local preload = package.preload["nvim-web-devicons"]

  package.loaded["nvim-web-devicons"] = module
  package.preload["nvim-web-devicons"] = nil

  local ok, err = xpcall(fn, debug.traceback)

  package.loaded["nvim-web-devicons"] = loaded
  package.preload["nvim-web-devicons"] = preload

  if not ok then
    error(err)
  end
end

local function with_missing_devicons(fn)
  local loaded = package.loaded["nvim-web-devicons"]
  local preload = package.preload["nvim-web-devicons"]

  package.loaded["nvim-web-devicons"] = nil
  package.preload["nvim-web-devicons"] = function()
    error("missing devicons")
  end

  local ok, err = xpcall(fn, debug.traceback)

  package.loaded["nvim-web-devicons"] = loaded
  package.preload["nvim-web-devicons"] = preload

  if not ok then
    error(err)
  end
end

t.test("devicons uses resolved file icons when available", function()
  with_config({
    icons = {
      devicons = true,
      file = "F",
    },
  }, function()
    with_fake_devicons({
      get_icon = function(_, _, opts)
        t.assert_true(opts.default)

        return "I", "DevIconTxt"
      end,
      get_default_icon = function()
        return {
          icon = "D",
          name = "Default",
        }
      end,
    }, function()
      local icon, highlight = devicons.file("/tmp/alpha.txt", "alpha.txt")

      t.assert_equal(icon, "I")
      t.assert_equal(highlight, "DevIconTxt")
    end)
  end)
end)

t.test("devicons uses devicons default icon when file icon is unavailable", function()
  with_config({
    icons = {
      devicons = true,
      file = "F",
    },
  }, function()
    with_fake_devicons({
      get_icon = function()
        return nil, nil
      end,
      get_default_icon = function()
        return {
          icon = "D",
          name = "Default",
        }
      end,
    }, function()
      local icon, highlight = devicons.file("/tmp/unknown.unknown", "unknown.unknown")

      t.assert_equal(icon, "D")
      t.assert_equal(highlight, "DevIconDefault")
    end)
  end)
end)

t.test("devicons falls back to configured file icon when devicons is missing", function()
  with_config({
    icons = {
      devicons = true,
      file = "F",
    },
  }, function()
    with_missing_devicons(function()
      local icon, highlight = devicons.file("/tmp/alpha.txt", "alpha.txt")

      t.assert_equal(icon, "F")
      t.assert_equal(highlight, "NvimSidebarFileIcon")
    end)
  end)
end)

t.test("devicons falls back to configured file icon when disabled", function()
  with_config({
    icons = {
      devicons = false,
      file = "F",
    },
  }, function()
    with_fake_devicons({
      get_icon = function()
        error("should not resolve devicons when disabled")
      end,
    }, function()
      local icon, highlight = devicons.file("/tmp/alpha.txt", "alpha.txt")

      t.assert_equal(icon, "F")
      t.assert_equal(highlight, "NvimSidebarFileIcon")
    end)
  end)
end)

t.run_if_direct("tests/unit/devicons_spec.lua")
