vim.opt.runtimepath:prepend(".")
vim.opt.swapfile = false

local sidebar = require("nvim-sidebar")
local fuzzy = require("nvim-sidebar.search.fuzzy")
local path = require("nvim-sidebar.util.path")
local state = require("nvim-sidebar.state")
local window = require("nvim-sidebar.ui.window")

local function assert_equal(actual, expected)
  assert(
    actual == expected,
    string.format("expected %s, got %s", vim.inspect(expected), vim.inspect(actual))
  )
end

local function displayed_buffer_name()
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
end

sidebar.setup({
  icons = {
    devicons = false,
  },
})

assert(type(sidebar.open) == "function")
assert(type(sidebar.close) == "function")
assert(type(sidebar.toggle) == "function")
assert(type(sidebar.focus) == "function")
assert(type(sidebar.refresh) == "function")
assert(type(sidebar.locate) == "function")
assert(type(sidebar.open_full_tree) == "function")

assert(fuzzy.match("README.md", "rme"))
assert(not fuzzy.match("README.md", "zzz"))
assert_equal(path.relative(vim.fn.getcwd(), path.join(vim.fn.getcwd(), "README.md")), "README.md")

local commands = vim.api.nvim_get_commands({})
assert(commands.NvimSidebar)
assert(commands.NvimSidebarToggle)
assert(commands.NvimSidebarRefresh)
assert(commands.NvimSidebarLocate)
assert(commands.NvimSidebarTree)

vim.cmd.edit("lua/nvim-sidebar/sources/files.lua")
local nested_file_path = path.normalize(vim.api.nvim_buf_get_name(0))
sidebar.locate("files")
assert_equal(vim.bo.filetype, "nvim-sidebar")
assert_equal(state.get_current_item().path, nested_file_path)
sidebar.close()

sidebar.open("files")
assert_equal(vim.bo.filetype, "nvim-sidebar")
assert_equal(displayed_buffer_name(), vim.fn.fnamemodify(vim.fn.getcwd(), ":~"))
sidebar.refresh()
sidebar.close()

sidebar.open("files")
vim.cmd.wincmd("p")
window.close_sidebar_if_last_regular_window()
assert(not window.is_sidebar_open())

vim.cmd.edit("README.md")
local readme_bufnr = vim.api.nvim_get_current_buf()
sidebar.locate("buffers")
assert_equal(vim.bo.filetype, "nvim-sidebar")
assert_equal(state.get_current_item().bufnr, readme_bufnr)
sidebar.close()

vim.cmd.edit("README.md")
sidebar.open("buffers")
assert_equal(vim.bo.filetype, "nvim-sidebar")
assert_equal(displayed_buffer_name(), "buffers")
sidebar.close()

sidebar.open_full_tree()
assert_equal(vim.bo.filetype, "nvim-sidebar")
assert_equal(displayed_buffer_name(), vim.fn.fnamemodify(vim.fn.getcwd(), ":~"))

vim.cmd("qa!")
