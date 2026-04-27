local t = require("tests.helpers")

local buffers = require("nvim-sidebar.sources.buffers")
local config = require("nvim-sidebar.config")
local path = require("nvim-sidebar.util.path")
local sidebar = require("nvim-sidebar")
local state = require("nvim-sidebar.state")

local function with_fake_devicons(icon, group, fn)
  local loaded = package.loaded["nvim-web-devicons"]
  local preload = package.preload["nvim-web-devicons"]

  package.loaded["nvim-web-devicons"] = {
    get_icon = function()
      return icon, group
    end,
  }
  package.preload["nvim-web-devicons"] = nil

  local ok, err = xpcall(fn, debug.traceback)

  package.loaded["nvim-web-devicons"] = loaded
  package.preload["nvim-web-devicons"] = preload

  if not ok then
    error(err)
  end
end

local function line_with_name(result, name)
  for index, line in ipairs(result.lines) do
    if line:find(name, 1, true) then
      return index, line
    end
  end

  return nil, nil
end

local function has_highlight(result, group, line, col_start, col_end)
  for _, highlight in ipairs(result.highlights or {}) do
    if
      highlight.group == group
      and highlight.line == line
      and highlight.col_start == col_start
      and highlight.col_end == col_end
    then
      return true
    end
  end

  return false
end

local function sidebar_cursor_line()
  return vim.api.nvim_win_get_cursor(state.sidebar.winid)[1]
end

local function line_by_bufnr(bufnr)
  for line, item in pairs(state.line_items[state.sidebar.bufnr] or {}) do
    if item.bufnr == bufnr then
      return line
    end
  end

  return nil
end

local function sidebar_text()
  return table.concat(vim.api.nvim_buf_get_lines(state.sidebar.bufnr, 0, -1, false), "\n")
end

local function wait_for_sidebar(predicate)
  local ok = vim.wait(1000, predicate, 10)

  t.assert_true(ok, "timed out waiting for sidebar update")
end

t.test("buffers view renders listed buffers and modified markers", function()
  t.temp_dir("buffers-open", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    vim.api.nvim_buf_set_lines(0, 0, 0, false, {
      "changed",
    })

    sidebar.open("buffers")

    local rendered = t.rendered_text()

    t.assert_contains(rendered, tostring(alpha_bufnr))
    t.assert_contains(rendered, "alpha.txt")
    t.assert_contains(rendered, "beta.txt")
    t.assert_contains(rendered, config.options.icons.modified .. " beta.txt")
    t.assert_equal(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:."), "buffers")
    t.assert_false(t.has_highlight_group(buffers.render(), "NvimSidebarCurrent"))
    t.assert_true(vim.wo[state.sidebar.winid].cursorline)
    t.assert_equal(sidebar_cursor_line(), line_by_bufnr(state.previous_buffer()))
  end)
end)

t.test("buffers view renders empty state when no listed buffers exist", function()
  t.temp_dir("buffers-open-empty", function()
    t.reset_plugin()
    vim.bo.buflisted = false

    sidebar.open("buffers")

    t.assert_equal(t.rendered_text(), "No buffers")
    t.assert_true(vim.wo[state.sidebar.winid].cursorline)
  end)
end)

t.test("buffers view separates file icons from names and highlights icons", function()
  with_fake_devicons("B", "DevIconTxt", function()
    t.temp_dir("buffers-open-icons", function(root)
      t.reset_plugin({
        icons = {
          devicons = true,
        },
      })
      t.write_file(path.join(root, "alpha.txt"), "alpha")

      vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))

      local result = buffers.render()
      local line_number, line = line_with_name(result, "alpha.txt")
      local bufnr = vim.api.nvim_get_current_buf()
      local buffer_number = string.format("%3d", bufnr)
      local icon_col = #(buffer_number .. " ")

      t.assert_equal(line, string.format("  %s B alpha.txt", buffer_number))
      t.assert_true(has_highlight(result, "DevIconTxt", line_number, icon_col + 2, icon_col + 3))
    end)
  end)
end)

t.test("buffers view supports configurable left padding", function()
  t.temp_dir("buffers-open-padding", function(root)
    t.reset_plugin({
      padding_left = 4,
    })
    t.write_file(path.join(root, "alpha.txt"), "alpha")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))

    local result = buffers.render()
    local _, line = line_with_name(result, "alpha.txt")

    t.assert_contains(
      line,
      "    " .. string.format("%3d", vim.api.nvim_get_current_buf()) .. " alpha.txt"
    )
  end)
end)

t.test("buffers view disambiguates duplicated file names with parent folder", function()
  t.temp_dir("buffers-open-duplicate-names", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "left", "init.lua"), "left")
    t.write_file(path.join(root, "right", "init.lua"), "right")
    t.write_file(path.join(root, "left", "unique.lua"), "unique")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "left", "init.lua")))
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "right", "init.lua")))
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "left", "unique.lua")))

    sidebar.open("buffers")

    local rendered = t.rendered_text()

    t.assert_contains(rendered, "left/init.lua")
    t.assert_contains(rendered, "right/init.lua")
    t.assert_contains(rendered, "unique.lua")
    t.assert_not_contains(rendered, "left/unique.lua")
  end)
end)

t.test("buffers cursor follows active editor buffer without rerendering", function()
  t.temp_dir("buffers-open-current-cursor", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    local beta_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("buffer " .. alpha_bufnr)

    sidebar.open("buffers")

    local before_lines = vim.api.nvim_buf_get_lines(state.sidebar.bufnr, 0, -1, false)

    t.assert_equal(sidebar_cursor_line(), line_by_bufnr(alpha_bufnr))

    vim.api.nvim_set_current_win(state.previous_window())

    t.assert_equal(sidebar_cursor_line(), line_by_bufnr(alpha_bufnr))

    vim.cmd("buffer " .. beta_bufnr)

    local after_lines = vim.api.nvim_buf_get_lines(state.sidebar.bufnr, 0, -1, false)

    t.assert_equal(table.concat(after_lines, "\n"), table.concat(before_lines, "\n"))
    t.assert_equal(sidebar_cursor_line(), line_by_bufnr(beta_bufnr))
  end)
end)

t.test("buffers cursor sync does not steal focus", function()
  t.temp_dir("buffers-open-current-cursor-focus", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))

    sidebar.open("buffers")

    local editor_winid = state.previous_window()
    vim.api.nvim_set_current_win(editor_winid)

    buffers.sync_current_cursor()

    t.assert_equal(vim.api.nvim_get_current_win(), editor_winid)
    t.assert_equal(sidebar_cursor_line(), line_by_bufnr(vim.api.nvim_get_current_buf()))
  end)
end)

t.test("buffers cursor is unchanged when current buffer is filtered out", function()
  t.temp_dir("buffers-open-current-cursor-filtered", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    state.search.query = "alpha"

    sidebar.open("buffers")

    t.assert_equal(line_by_bufnr(state.previous_buffer()), nil)
    t.assert_equal(sidebar_cursor_line(), 1)
  end)
end)

t.test("buffers view refreshes after bdelete of hidden buffer", function()
  t.temp_dir("buffers-open-bdelete", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))

    sidebar.open("buffers")
    vim.api.nvim_set_current_win(state.previous_window())
    vim.cmd("bdelete " .. alpha_bufnr)

    wait_for_sidebar(function()
      local text = sidebar_text()

      return text:find("alpha.txt", 1, true) == nil and text:find("beta.txt", 1, true) ~= nil
    end)

    t.assert_not_contains(sidebar_text(), "alpha.txt")
    t.assert_contains(sidebar_text(), "beta.txt")
    t.assert_not_contains(sidebar_text(), "[No Name]")
  end)
end)

t.test("buffers view refreshes after bwipeout of hidden buffer", function()
  t.temp_dir("buffers-open-bwipeout", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))

    sidebar.open("buffers")
    vim.api.nvim_set_current_win(state.previous_window())
    vim.cmd("bwipeout " .. alpha_bufnr)

    wait_for_sidebar(function()
      local text = sidebar_text()

      return text:find("alpha.txt", 1, true) == nil and text:find("beta.txt", 1, true) ~= nil
    end)

    t.assert_not_contains(sidebar_text(), "alpha.txt")
    t.assert_contains(sidebar_text(), "beta.txt")
    t.assert_not_contains(sidebar_text(), "[No Name]")
  end)
end)

t.test("buffers sidebar uses source name as local statusline title", function()
  t.temp_dir("buffers-open-title", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))

    sidebar.open("buffers")

    t.assert_equal(vim.wo.statusline, " buffers")
  end)
end)

t.test("buffers open action switches previous window to selected buffer", function()
  t.temp_dir("buffers-open-action", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))

    sidebar.open("buffers")
    buffers.actions.open(t.item_by_name("alpha.txt"))

    t.assert_equal(vim.api.nvim_get_current_buf(), alpha_bufnr)
  end)
end)

t.test("buffers open action keeps using focused editor window after owner scan", function()
  t.temp_dir("buffers-open-action-previous-window", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_winid = vim.api.nvim_get_current_win()
    vim.cmd("vsplit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    vim.api.nvim_set_current_win(alpha_winid)

    sidebar.open("buffers")
    buffers.actions.open(t.item_by_name("beta.txt"))

    t.assert_equal(vim.api.nvim_get_current_win(), alpha_winid)
    t.assert_equal(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"), "beta.txt")
  end)
end)

t.test("buffers tab moves to next buffer and keeps sidebar focus", function()
  t.temp_dir("buffers-tab-next", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("vsplit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    local beta_winid = vim.api.nvim_get_current_win()
    local beta_bufnr = vim.api.nvim_get_current_buf()

    sidebar.open("buffers")

    t.trigger_normal_mapping(line_by_bufnr(alpha_bufnr), "<Tab>")

    t.assert_equal(vim.api.nvim_get_current_win(), state.sidebar.winid)
    t.assert_equal(sidebar_cursor_line(), line_by_bufnr(beta_bufnr))
    t.assert_equal(vim.api.nvim_win_get_buf(beta_winid), beta_bufnr)
    t.assert_equal(state.previous_window(), beta_winid)
    t.assert_equal(state.previous_buffer(), beta_bufnr)
  end)
end)

t.test("buffers shift-tab wraps to previous buffer and keeps sidebar focus", function()
  t.temp_dir("buffers-tab-previous", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("vsplit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    local beta_bufnr = vim.api.nvim_get_current_buf()

    sidebar.open("buffers")

    t.trigger_normal_mapping(line_by_bufnr(alpha_bufnr), "<S-Tab>")

    t.assert_equal(vim.api.nvim_get_current_win(), state.sidebar.winid)
    t.assert_equal(sidebar_cursor_line(), line_by_bufnr(beta_bufnr))
  end)
end)

t.test("buffers tab opens hidden buffer in remembered owner window", function()
  t.temp_dir("buffers-tab-hidden-owner", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")
    t.write_file(path.join(root, "gamma.txt"), "gamma")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    vim.cmd("vsplit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    local beta_winid = vim.api.nvim_get_current_win()
    local beta_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "gamma.txt")))
    local gamma_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("buffer " .. beta_bufnr)

    sidebar.open("buffers")

    t.trigger_normal_mapping(line_by_bufnr(beta_bufnr), "<Tab>")

    t.assert_equal(vim.api.nvim_get_current_win(), state.sidebar.winid)
    t.assert_equal(sidebar_cursor_line(), line_by_bufnr(gamma_bufnr))
    t.assert_equal(vim.api.nvim_win_get_buf(beta_winid), gamma_bufnr)
  end)
end)

t.test("buffers tab falls back to previous editor window for stale owner", function()
  t.temp_dir("buffers-tab-stale-owner", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_winid = vim.api.nvim_get_current_win()
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    local beta_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("buffer " .. alpha_bufnr)

    state.buffer_windows[beta_bufnr] = 999999

    sidebar.open("buffers")

    t.trigger_normal_mapping(line_by_bufnr(alpha_bufnr), "<Tab>")

    t.assert_equal(vim.api.nvim_get_current_win(), state.sidebar.winid)
    t.assert_equal(vim.api.nvim_win_get_buf(alpha_winid), beta_bufnr)
  end)
end)

t.run_if_direct("tests/buffers/open_spec.lua")
