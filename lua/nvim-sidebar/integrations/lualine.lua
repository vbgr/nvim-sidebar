local M = {}

local path_separator = package.config:sub(1, 1)

local function display_width(value)
  return vim.fn.strdisplaywidth(value)
end

local function is_path_like(value)
  return value:sub(1, 1) == "~" or value:sub(1, 1) == "/" or value:match("^%a:[/\\]") ~= nil
end

local function truncate(value, max_width)
  if display_width(value) <= max_width then
    return value
  end

  return vim.fn.strcharpart(value, 0, max_width)
end

local function normalized_path(value)
  local path = vim.fn.fnamemodify(value, ":~")

  if #path > 1 and vim.endswith(path, path_separator) then
    path = path:sub(1, -2)
  end

  return path
end

local function shorten_path(value, max_width)
  local path = normalized_path(value)

  if display_width(path) <= max_width then
    return path
  end

  local segments = vim.split(path, path_separator, {
    plain = true,
  })

  if #segments <= 1 then
    return truncate(path, max_width)
  end

  local root = segments[1]
  local target = segments[#segments]
  local directories = #segments > 2
      and (table.concat(segments, path_separator, 2, #segments - 1) .. path_separator)
    or ""
  local cache = {}

  for length = 3, 1, -1 do
    cache[length] = vim.fn.pathshorten(directories, length)

    local short = string.format("%s" .. path_separator .. "%s%s", root, cache[length], target)

    if display_width(short) <= max_width then
      return short
    end
  end

  for length = 3, 1, -1 do
    local short =
      string.format("%s" .. path_separator .. "%s%s", root, cache[length], target:sub(1, length))

    if display_width(short) <= max_width then
      return short
    end
  end

  return string.format("%s" .. path_separator .. "%s%s", root, cache[1], target:sub(1, 1))
end

local function title_for_current_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local title = vim.b[bufnr].nvim_sidebar_title

  if title ~= nil and title ~= "" then
    return title
  end

  local name = vim.api.nvim_buf_get_name(bufnr)

  if name == "" then
    return ""
  end

  return vim.fn.fnamemodify(name, ":~")
end

function M.title()
  local title = title_for_current_buffer()
  local max_width = math.max(vim.api.nvim_win_get_width(0) - 7, 1)

  if is_path_like(title) then
    return shorten_path(title, max_width)
  end

  return truncate(title, max_width)
end

M.sections = {
  lualine_a = {
    M.title,
  },
}

M.filetypes = {
  "nvim-sidebar",
}

return M
