local M = {}

vim.opt.runtimepath:prepend(".")
vim.opt.swapfile = false

local path = require("nvim-sidebar.util.path")
local uv = vim.uv or vim.loop

local tests = {}

function M.test(name, fn)
  table.insert(tests, {
    name = name,
    fn = fn,
  })
end

function M.assert_equal(actual, expected, message)
  assert(
    actual == expected,
    message or string.format("expected %s, got %s", vim.inspect(expected), vim.inspect(actual))
  )
end

function M.assert_true(value, message)
  assert(value == true, message or string.format("expected true, got %s", vim.inspect(value)))
end

function M.assert_false(value, message)
  assert(value == false, message or string.format("expected false, got %s", vim.inspect(value)))
end

function M.assert_contains(value, needle, message)
  assert(
    tostring(value):find(needle, 1, true) ~= nil,
    message or string.format("expected %s to contain %s", vim.inspect(value), vim.inspect(needle))
  )
end

function M.assert_not_contains(value, needle, message)
  assert(
    tostring(value):find(needle, 1, true) == nil,
    message
      or string.format("expected %s to not contain %s", vim.inspect(value), vim.inspect(needle))
  )
end

function M.assert_file_exists(file_path)
  assert(uv.fs_stat(file_path) ~= nil, "expected file to exist: " .. file_path)
end

function M.assert_file_missing(file_path)
  assert(uv.fs_stat(file_path) == nil, "expected file to be missing: " .. file_path)
end

function M.write_file(file_path, content)
  vim.fn.mkdir(path.dirname(file_path), "p")
  vim.fn.writefile(
    vim.split(content, "\n", {
      plain = true,
    }),
    file_path
  )
end

function M.read_file(file_path)
  return table.concat(vim.fn.readfile(file_path), "\n")
end

function M.temp_dir(name, fn)
  local requested_root = path.join("/tmp", "nvim-sidebar-tests-" .. name .. "-" .. vim.fn.getpid())
  local cwd = vim.fn.getcwd()

  vim.fn.delete(requested_root, "rf")
  vim.fn.mkdir(requested_root, "p")

  local root = uv.fs_realpath(requested_root) or requested_root

  vim.cmd("cd " .. vim.fn.fnameescape(root))

  local ok, err = xpcall(function()
    fn(root)
  end, debug.traceback)

  vim.cmd("cd " .. vim.fn.fnameescape(cwd))
  pcall(M.reset_editor)
  vim.fn.delete(root, "rf")

  if not ok then
    error(err)
  end
end

function M.reset_editor()
  pcall(vim.cmd, "silent! only")

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_delete, bufnr, {
        force = true,
      })
    end
  end

  vim.cmd("enew!")
  vim.bo.buftype = ""
  vim.bo.buflisted = true
end

function M.reset_plugin(opts)
  local sidebar = require("nvim-sidebar")
  local state = require("nvim-sidebar.state")

  state.sidebar = {
    bufnr = nil,
    winid = nil,
  }
  state.full = {
    bufnr = nil,
    winid = nil,
  }
  state.previous = {
    bufnr = nil,
    winid = nil,
  }
  state.active_source = nil
  state.render_mode = "sidebar"
  state.line_items = {}
  state.search = {
    query = "",
  }
  state.cursor = {
    restore_path = nil,
    restore_bufnr = nil,
  }
  state.fstree = {
    expanded = {},
    clipboard = {
      mode = nil,
      paths = {},
    },
  }

  sidebar.setup(vim.tbl_deep_extend("force", {
    icons = {
      devicons = false,
    },
  }, opts or {}))
end

function M.buffer_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

function M.rendered_text()
  return table.concat(M.buffer_lines(), "\n")
end

function M.find_line(pattern)
  for line, text in ipairs(M.buffer_lines()) do
    if text:find(pattern, 1, false) then
      return line, text
    end
  end

  return nil, nil
end

function M.item_names()
  local state = require("nvim-sidebar.state")
  local names = {}

  for _, item in pairs(state.line_items[vim.api.nvim_get_current_buf()] or {}) do
    table.insert(names, item.name)
  end

  return table.concat(names, "\n")
end

function M.item_by_name(name)
  local state = require("nvim-sidebar.state")

  for _, item in pairs(state.line_items[vim.api.nvim_get_current_buf()] or {}) do
    if item.name == name then
      return item
    end
  end

  return nil
end

function M.line_by_name(name)
  local state = require("nvim-sidebar.state")

  for line, item in pairs(state.line_items[vim.api.nvim_get_current_buf()] or {}) do
    if item.name == name then
      return line, item
    end
  end

  return nil, nil
end

function M.trigger_normal_mapping(line, lhs)
  vim.api.nvim_win_set_cursor(0, {
    line,
    0,
  })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "x", false)
end

function M.trigger_visual_mapping(start_line, end_line, lhs)
  vim.api.nvim_win_set_cursor(0, {
    start_line,
    0,
  })

  local count = math.abs(end_line - start_line)
  local motion = end_line >= start_line and string.rep("j", count) or string.rep("k", count)

  vim.cmd("normal! V" .. motion)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "x", false)
end

function M.has_highlight_group(result, group)
  for _, highlight in ipairs(result.highlights or {}) do
    if highlight.group == group then
      return true
    end
  end

  return false
end

function M.open_fixture_tree(root, opts)
  M.reset_plugin(opts)
  M.write_file(path.join(root, "alpha.txt"), "alpha")
  M.write_file(path.join(root, "zeta.txt"), "zeta")
  M.write_file(path.join(root, "dir-b", "child.txt"), "child")
  M.write_file(path.join(root, "dir-a", "nested", "deep.md"), "deep")
end

function M.run()
  local failures = 0

  for _, test in ipairs(tests) do
    M.reset_editor()

    local ok, err = xpcall(test.fn, debug.traceback)

    if ok then
      print("ok - " .. test.name)
    else
      failures = failures + 1
      print("not ok - " .. test.name)
      print(err)
    end
  end

  if failures > 0 then
    vim.cmd("cquit")
  end

  vim.cmd("qa!")
end

function M.run_if_direct(script_path)
  if arg == nil or arg[0] == nil then
    return
  end

  local current = vim.fn.fnamemodify(arg[0], ":p")
  local expected = vim.fn.fnamemodify(script_path, ":p")

  if current == expected then
    M.run()
  end
end

return M
