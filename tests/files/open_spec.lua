local t = require("tests.helpers")

local expand = require("nvim-sidebar.fstree.expand")
local files = require("nvim-sidebar.sources.files")
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

local function sidebar_line(pattern)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(state.sidebar.bufnr, 0, -1, false)) do
    if line:find(pattern, 1, true) then
      return line
    end
  end

  return nil
end

t.test("files view renders cwd path, directories first, and directory highlights", function()
  t.temp_dir("files-open", function(root)
    t.open_fixture_tree(root)

    sidebar.open("files")

    local dir_a_line = t.line_by_name("dir-a")
    local dir_b_line = t.line_by_name("dir-b")
    local alpha_line = t.line_by_name("alpha.txt")
    local zeta_line = t.line_by_name("zeta.txt")

    t.assert_equal(
      vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:."),
      vim.fn.fnamemodify(root, ":~")
    )
    t.assert_true(dir_a_line < alpha_line)
    t.assert_true(dir_b_line < alpha_line)
    t.assert_true(alpha_line < zeta_line)
    t.assert_true(t.has_highlight_group(
      files.render({
        mode = "sidebar",
      }),
      "NvimSidebarDirectory"
    ))
  end)
end)

t.test("files view renders empty state when cwd has no entries", function()
  t.temp_dir("files-open-empty", function()
    t.reset_plugin()

    sidebar.open("files")

    t.assert_equal(t.rendered_text(), "No files")
  end)
end)

t.test("files view separates file icons from names and highlights icons", function()
  with_fake_devicons("I", "DevIconTxt", function()
    t.temp_dir("files-open-icons", function(root)
      t.reset_plugin({
        icons = {
          devicons = true,
        },
      })
      t.write_file(path.join(root, "alpha.txt"), "alpha")

      local result = files.render({
        mode = "sidebar",
      })

      t.assert_equal(result.lines[1], "   I alpha.txt")
      t.assert_true(has_highlight(result, "DevIconTxt", 1, 3, 4))
    end)
  end)
end)

t.test("files view supports configurable left padding", function()
  t.temp_dir("files-open-padding", function(root)
    t.reset_plugin({
      padding_left = 4,
    })
    t.write_file(path.join(root, "alpha.txt"), "alpha")

    local result = files.render({
      mode = "sidebar",
    })

    t.assert_equal(result.lines[1], "     alpha.txt")
  end)
end)

t.test("files sidebar disables listchars in its window", function()
  t.temp_dir("files-open-listchars", function(root)
    t.open_fixture_tree(root)
    vim.wo.list = true

    sidebar.open("files")

    t.assert_false(vim.wo.list)
  end)
end)

t.test("files sidebar uses cwd path as local statusline title", function()
  t.temp_dir("files-open-title", function(root)
    t.open_fixture_tree(root)

    sidebar.open("files")

    t.assert_equal(vim.wo.statusline, " " .. vim.fn.fnamemodify(root, ":~"))
  end)
end)

t.test("files view marks files opened in buffers", function()
  t.temp_dir("files-open-buffer-marker", function(root)
    t.open_fixture_tree(root)
    vim.cmd("edit " .. vim.fn.fnameescape(path.join(root, "alpha.txt")))

    sidebar.open("files")

    t.assert_contains(select(2, t.find_line("alpha.txt")), " o")
  end)
end)

t.test("files view does not render excluded entries", function()
  t.temp_dir("files-open-exclusions", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, ".DS_Store"), "metadata")
    t.write_file(path.join(root, "module.pyc"), "bytecode")
    vim.fn.mkdir(path.join(root, "__pycache__"), "p")
    vim.fn.mkdir(path.join(root, "node_modules"), "p")
    t.write_file(path.join(root, "visible.txt"), "visible")

    sidebar.open("files")

    local rendered = t.rendered_text()

    t.assert_contains(rendered, "visible.txt")
    t.assert_not_contains(rendered, ".DS_Store")
    t.assert_not_contains(rendered, "module.pyc")
    t.assert_not_contains(rendered, "__pycache__")
    t.assert_not_contains(rendered, "node_modules")
  end)
end)

t.test("files open action expands directories and opens files in previous window", function()
  t.temp_dir("files-open-action", function(root)
    t.open_fixture_tree(root)

    sidebar.open("files")
    files.actions.open(t.item_by_name("dir-b"), {
      refresh = sidebar.refresh,
    })

    t.assert_true(expand.is_expanded(path.join(root, "dir-b")))

    files.actions.open(t.item_by_name("child.txt"), {
      refresh = sidebar.refresh,
    })

    t.assert_equal(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"), "child.txt")
  end)
end)

t.test("files open action handles file names with spaces", function()
  t.temp_dir("files-open-spaces", function(root)
    t.reset_plugin()
    t.write_file(path.join(root, "file with spaces.txt"), "spaces")

    sidebar.open("files")
    files.actions.open(t.item_by_name("file with spaces.txt"), {
      mode = "sidebar",
      refresh = sidebar.refresh,
    })

    t.assert_equal(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"), "file with spaces.txt")
  end)
end)

t.test("files open action refreshes opened marker without stealing focus", function()
  t.temp_dir("files-open-action-marker", function(root)
    t.open_fixture_tree(root)

    sidebar.open("files")

    local editor_winid = state.previous_window()

    files.actions.open(t.item_by_name("alpha.txt"), {
      mode = "sidebar",
      refresh = sidebar.refresh,
    })

    t.assert_equal(vim.api.nvim_get_current_win(), editor_winid)
    t.assert_equal(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"), "alpha.txt")
    t.assert_contains(sidebar_line("alpha.txt"), " o")
  end)
end)

t.run_if_direct("tests/files/open_spec.lua")
