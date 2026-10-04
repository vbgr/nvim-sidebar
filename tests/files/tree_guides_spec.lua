local t = require("tests.helpers")

local expand = require("nvim-sidebar.fstree.expand")
local files = require("nvim-sidebar.sources.files")
local path = require("nvim-sidebar.util.path")
local state = require("nvim-sidebar.state")

local ICONS = {
  file = "f",
  folder_open = "D",
  folder_closed = "d",
  expanded = "v",
  collapsed = ">",
}

local function reset(tree)
  t.reset_plugin({
    icons = ICONS,
    tree = tree,
  })
end

local function write_project(root)
  t.write_file(path.join(root, "src", "lua", "a.lua"), "a")
  t.write_file(path.join(root, "src", "tests", "a_spec.lua"), "a")
  t.write_file(path.join(root, "src", "tests", "b_spec.lua"), "b")
  t.write_file(path.join(root, "src", "README.md"), "readme")
  expand.expand(path.join(root, "src"))
  expand.expand(path.join(root, "src", "tests"))
end

local function render(mode)
  return files.render({
    mode = mode or "sidebar",
  })
end

local function find_highlight(result, group, line, col_start)
  for _, highlight in ipairs(result.highlights) do
    if
      highlight.group == group
      and highlight.line == line
      and (col_start == nil or highlight.col_start == col_start)
    then
      return highlight
    end
  end

  return nil
end

t.test("files tree shows chevrons before folder icons and keeps files aligned", function()
  t.temp_dir("tree-chevrons", function(root)
    reset()
    write_project(root)

    local lines = render().lines

    t.assert_equal(lines[1], "  v D src")
    t.assert_equal(lines[2], "    > d lua")
    t.assert_equal(lines[3], "    v D tests")
    t.assert_equal(lines[4], "        f a_spec.lua")
    t.assert_equal(lines[5], "        f b_spec.lua")
    t.assert_equal(lines[6], "      f README.md")
    t.assert_equal(lines[2]:find("lua", 1, true), lines[6]:find("README", 1, true))
  end)
end)

t.test("files tree honors custom chevron icons", function()
  t.temp_dir("tree-custom-chevrons", function(root)
    t.reset_plugin({
      icons = vim.tbl_extend("force", ICONS, {
        expanded = "-",
        collapsed = "+",
      }),
    })
    write_project(root)

    local lines = render().lines

    t.assert_equal(lines[1], "  - D src")
    t.assert_equal(lines[2], "    + d lua")
  end)
end)

t.test("files tree draws connectors that reach the file icon with indent_markers", function()
  t.temp_dir("tree-guides", function(root)
    reset({
      indent_markers = true,
    })
    write_project(root)

    local lines = render().lines

    t.assert_equal(lines[1], "  v D src")
    t.assert_equal(lines[2], "  ├─ > d lua")
    t.assert_equal(lines[3], "  ├─ v D tests")
    t.assert_equal(lines[4], "  │  ├─── f a_spec.lua")
    t.assert_equal(lines[5], "  │  └─── f b_spec.lua")
    t.assert_equal(lines[6], "  └─── f README.md")
  end)
end)

t.test("files tree leaves blank guide cells under last children", function()
  t.temp_dir("tree-guides-last", function(root)
    reset({
      indent_markers = true,
    })
    t.write_file(path.join(root, "outer", "inner", "leaf.txt"), "leaf")
    expand.expand(path.join(root, "outer"))
    expand.expand(path.join(root, "outer", "inner"))

    local lines = render().lines

    t.assert_equal(lines[1], "  v D outer")
    t.assert_equal(lines[2], "  └─ v D inner")
    t.assert_equal(lines[3], "     └─── f leaf.txt")
  end)
end)

t.test("files tree suppresses guides while searching but keeps indentation", function()
  t.temp_dir("tree-guides-search", function(root)
    reset({
      indent_markers = true,
    })
    write_project(root)
    state.search.query = "a_spec"

    local lines = render().lines

    t.assert_equal(#lines, 1)
    t.assert_equal(lines[1], "          f a_spec.lua")
  end)
end)

t.test("files tree highlights guides and chevrons with NvimSidebarIndent", function()
  t.temp_dir("tree-guide-highlights", function(root)
    reset({
      indent_markers = true,
    })
    write_project(root)

    local result = render()
    local guide_end = 2 + #"│  " + #"├───"
    local guide = find_highlight(result, "NvimSidebarIndent", 4)

    t.assert_true(guide ~= nil)
    t.assert_equal(guide.col_start, 2)
    t.assert_equal(guide.col_end, guide_end)
    t.assert_equal(result.lines[4]:sub(guide.col_start + 1, guide.col_end), "│  ├───")

    local icon = find_highlight(result, "NvimSidebarFileIcon", 4)

    t.assert_equal(icon.col_start, guide_end + 1)
    t.assert_equal(icon.col_end, guide_end + 1 + #"f")

    local chevron = find_highlight(result, "NvimSidebarIndent", 2, 2 + #"├─ ")

    t.assert_true(chevron ~= nil)
    t.assert_equal(chevron.col_end, 2 + #"├─ " + #">")

    local directory = find_highlight(result, "NvimSidebarDirectory", 2)

    t.assert_equal(directory.col_start, 2 + #"├─ " + #">" + 1)
  end)
end)

t.test("files tree colors chevrons even when guides are off", function()
  t.temp_dir("tree-chevron-highlights", function(root)
    reset()
    write_project(root)

    local result = render()
    local chevron = find_highlight(result, "NvimSidebarIndent", 1)

    t.assert_true(chevron ~= nil)
    t.assert_equal(chevron.col_start, 2)
    t.assert_equal(chevron.col_end, 2 + #"v")
    t.assert_true(find_highlight(result, "NvimSidebarIndent", 4) == nil)
    t.assert_equal(find_highlight(result, "NvimSidebarDirectory", 1).col_start, 2 + #"v" + 1)
  end)
end)

t.test("files tree puts child connectors directly under the parent chevron", function()
  t.temp_dir("tree-guides-aligned", function(root)
    reset({
      indent_markers = true,
    })
    write_project(root)

    local lines = render().lines

    local function display_col(line, needle)
      local byte = line:find(needle, 1, true)

      return vim.fn.strdisplaywidth(line:sub(1, byte - 1))
    end

    t.assert_equal(display_col(lines[2], "├"), display_col(lines[1], "v"))
    t.assert_equal(display_col(lines[3], "├"), display_col(lines[1], "v"))
    t.assert_equal(display_col(lines[4], "├"), display_col(lines[3], "v"))
    t.assert_equal(display_col(lines[4], "│"), display_col(lines[1], "v"))
    t.assert_equal(display_col(lines[6], "└"), display_col(lines[1], "v"))
  end)
end)

t.test("files full tree keeps guides and right columns aligned", function()
  t.temp_dir("tree-guides-full", function(root)
    reset({
      indent_markers = true,
    })
    write_project(root)

    local lines = render("full").lines
    local width = vim.fn.strdisplaywidth(lines[1])

    t.assert_contains(lines[4], "│  ├───")

    for _, line in ipairs(lines) do
      t.assert_equal(vim.fn.strdisplaywidth(line), width)
    end
  end)
end)

t.run_if_direct("tests/files/tree_guides_spec.lua")
