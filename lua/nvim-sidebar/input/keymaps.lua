local actions = require("nvim-sidebar.input.actions")
local config = require("nvim-sidebar.config")

local M = {}

local function in_visual_mode()
  local mode = vim.fn.mode()
  return mode == "v" or mode == "V" or mode == "\22"
end

local function visual_range()
  if not in_visual_mode() then
    return nil
  end

  return {
    start_line = vim.fn.line("v"),
    end_line = vim.fn.line("."),
  }
end

local function map(bufnr, modes, lhs, action)
  if lhs == nil or lhs == "" then
    return
  end

  vim.keymap.set(modes, lhs, function()
    local range = visual_range()
    local visual = range ~= nil

    if visual then
      vim.cmd("normal! \027")
    end

    actions.dispatch(action, {
      visual = visual,
      range = range,
    })
  end, {
    buffer = bufnr,
    nowait = true,
    silent = true,
  })
end

function M.apply(bufnr)
  local maps = config.options.keymaps

  map(bufnr, { "n" }, maps.open, "open")
  map(bufnr, { "n" }, maps.collapse, "collapse")
  map(bufnr, { "n" }, maps.search, "search")
  map(bufnr, { "n" }, maps.new_file, "new_file")
  map(bufnr, { "n" }, maps.new_directory, "new_directory")
  map(bufnr, { "n", "x" }, maps.trash, "trash")
  map(bufnr, { "n", "x" }, maps.copy, "copy")
  map(bufnr, { "n", "x" }, maps.cut, "cut")
  map(bufnr, { "n" }, maps.paste, "paste")
  map(bufnr, { "n", "x" }, maps.yank_name, "yank_name")
  map(bufnr, { "n", "x" }, maps.yank_path, "yank_path")
  map(bufnr, { "n", "x" }, maps.duplicate, "duplicate")
  map(bufnr, { "n" }, maps.rename, "rename")
  map(bufnr, { "n" }, maps.locate, "locate")
  map(bufnr, { "n" }, maps.refresh, "refresh")
  map(bufnr, { "n" }, maps.close, "close")
end

return M
