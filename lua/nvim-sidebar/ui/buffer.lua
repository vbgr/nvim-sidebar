local M = {}

local function create(name, filetype)
  local bufnr = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_name(bufnr, name)
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].filetype = filetype
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].swapfile = false

  return bufnr
end

local function valid(bufnr)
  return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
end

function M.set_name(bufnr, name)
  if name == nil or name == "" or vim.api.nvim_buf_get_name(bufnr) == name then
    return
  end

  local ok = pcall(vim.api.nvim_buf_set_name, bufnr, name)

  if ok then
    return
  end

  pcall(vim.api.nvim_buf_set_name, bufnr, name .. " [" .. bufnr .. "]")
end

function M.ensure_sidebar()
  local state = require("nvim-sidebar.state")

  if valid(state.sidebar.bufnr) then
    return state.sidebar.bufnr
  end

  state.sidebar.bufnr = create("nvim-sidebar", "nvim-sidebar")
  return state.sidebar.bufnr
end

function M.ensure_full()
  local state = require("nvim-sidebar.state")

  if valid(state.full.bufnr) then
    return state.full.bufnr
  end

  state.full.bufnr = create("nvim-sidebar-tree", "nvim-sidebar")
  return state.full.bufnr
end

function M.set_lines(bufnr, lines)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modified = false
  vim.bo[bufnr].modifiable = false
end

return M
