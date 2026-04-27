local t = require("tests.helpers")

local buffers = require("nvim-sidebar.sources.buffers")
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

local function current_highlight_lines()
  local ns = vim.api.nvim_create_namespace("nvim-sidebar-current-buffer")
  local marks = vim.api.nvim_buf_get_extmarks(state.sidebar.bufnr, ns, 0, -1, {
    details = true,
  })
  local lines = {}

  for _, mark in ipairs(marks) do
    table.insert(lines, mark[2] + 1)
  end

  return lines
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

local function listed_editor_buffers()
  local result = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_valid(bufnr)
      and vim.bo[bufnr].buflisted
      and not state.is_plugin_buffer(bufnr)
    then
      table.insert(result, bufnr)
    end
  end

  return result
end

t.test("buffers view renders listed buffers and modified markers", function()
  t.temp_dir("buffers-open", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    local beta_bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(0, 0, 0, false, {
      "changed",
    })

    sidebar.open("buffers")

    local rendered = t.rendered_text()

    t.assert_contains(rendered, tostring(alpha_bufnr))
    t.assert_contains(rendered, "alpha.txt")
    t.assert_contains(rendered, "beta.txt")
    t.assert_contains(rendered, "* beta.txt")
    t.assert_equal(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:."), "buffers")
    t.assert_false(t.has_highlight_group(buffers.render(), "NvimSidebarCurrent"))
    t.assert_equal(current_highlight_lines()[1], line_by_bufnr(beta_bufnr))
  end)
end)

t.test("buffers view renders empty state when no listed buffers exist", function()
  t.temp_dir("buffers-open-empty", function()
    t.reset_plugin()
    vim.bo.buflisted = false

    sidebar.open("buffers")

    t.assert_equal(t.rendered_text(), "No buffers")
    t.assert_equal(#current_highlight_lines(), 0)
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
      local buffer_number = string.format("%2d", bufnr)
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
      "    " .. string.format("%2d", vim.api.nvim_get_current_buf()) .. " alpha.txt"
    )
  end)
end)

t.test("buffers current highlight follows active editor buffer without rerendering", function()
  t.temp_dir("buffers-open-current-highlight", function(root)
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

    t.assert_equal(current_highlight_lines()[1], line_by_bufnr(alpha_bufnr))

    vim.api.nvim_set_current_win(state.previous_window())
    vim.cmd("buffer " .. beta_bufnr)

    local after_lines = vim.api.nvim_buf_get_lines(state.sidebar.bufnr, 0, -1, false)

    t.assert_equal(table.concat(after_lines, "\n"), table.concat(before_lines, "\n"))
    t.assert_equal(current_highlight_lines()[1], line_by_bufnr(beta_bufnr))
  end)
end)

t.test("buffers current highlight is absent when current buffer is filtered out", function()
  t.temp_dir("buffers-open-current-highlight-filtered", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))
    state.search.query = "alpha"

    sidebar.open("buffers")

    t.assert_equal(#current_highlight_lines(), 0)
  end)
end)

t.test("buffers view refreshes after bdelete of current editor buffer", function()
  t.temp_dir("buffers-open-bdelete", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))

    sidebar.open("buffers")
    vim.api.nvim_set_current_win(state.previous_window())
    vim.cmd("buffer " .. alpha_bufnr)
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

t.test("buffers view refreshes after bwipeout of current editor buffer", function()
  t.temp_dir("buffers-open-bwipeout", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")
    t.write_file(path.join(root, "beta.txt"), "beta")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "beta.txt")))

    sidebar.open("buffers")
    vim.api.nvim_set_current_win(state.previous_window())
    vim.cmd("buffer " .. alpha_bufnr)
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

t.test("buffers view creates unnamed buffer after bdelete of last editor buffer", function()
  t.temp_dir("buffers-open-bdelete-last", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()

    sidebar.open("buffers")
    vim.api.nvim_set_current_win(state.previous_window())
    vim.cmd("bdelete " .. alpha_bufnr)

    wait_for_sidebar(function()
      return sidebar_text():find("[No Name]", 1, true) ~= nil
    end)

    local listed = listed_editor_buffers()

    t.assert_equal(#listed, 1)
    t.assert_equal(vim.api.nvim_buf_get_name(listed[1]), "")
    t.assert_contains(sidebar_text(), "[No Name]")
    t.assert_not_contains(sidebar_text(), "alpha.txt")
  end)
end)

t.test("buffers view creates unnamed buffer after bwipeout of last editor buffer", function()
  t.temp_dir("buffers-open-bwipeout-last", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "alpha.txt"), "alpha")

    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
    local alpha_bufnr = vim.api.nvim_get_current_buf()

    sidebar.open("buffers")
    vim.api.nvim_set_current_win(state.previous_window())
    vim.cmd("bwipeout " .. alpha_bufnr)

    wait_for_sidebar(function()
      return sidebar_text():find("[No Name]", 1, true) ~= nil
    end)

    local listed = listed_editor_buffers()

    t.assert_equal(#listed, 1)
    t.assert_equal(vim.api.nvim_buf_get_name(listed[1]), "")
    t.assert_contains(sidebar_text(), "[No Name]")
    t.assert_not_contains(sidebar_text(), "alpha.txt")
  end)
end)

t.test(
  "buffers view creates unnamed buffer after deleting last editor buffer from sidebar",
  function()
    t.temp_dir("buffers-open-bdelete-last-from-sidebar", function(root)
      t.reset_plugin()
      t.write_file(path.join(root, "alpha.txt"), "alpha")

      vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))
      local alpha_bufnr = vim.api.nvim_get_current_buf()

      sidebar.open("buffers")
      vim.cmd("bdelete " .. alpha_bufnr)

      wait_for_sidebar(function()
        return sidebar_text():find("[No Name]", 1, true) ~= nil
      end)

      local listed = listed_editor_buffers()

      t.assert_equal(#listed, 1)
      t.assert_equal(vim.api.nvim_buf_get_name(listed[1]), "")
      t.assert_contains(sidebar_text(), "[No Name]")
      t.assert_not_contains(sidebar_text(), "alpha.txt")
    end)
  end
)

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

t.run_if_direct("tests/buffers/open_spec.lua")
