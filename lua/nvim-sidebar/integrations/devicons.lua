local config = require("nvim-sidebar.config")

local M = {}

local function fallback_icon()
  return config.options.icons.file, "NvimSidebarFileIcon"
end

local function default_icon(devicons)
  if type(devicons.get_default_icon) ~= "function" then
    return nil, nil
  end

  local icon = devicons.get_default_icon()

  if type(icon) ~= "table" or icon.icon == nil then
    return nil, nil
  end

  local highlight = icon.name and ("DevIcon" .. icon.name) or "NvimSidebarFileIcon"

  return icon.icon, highlight
end

function M.file(file_path, name)
  if not config.options.icons.devicons then
    return fallback_icon()
  end

  local ok, devicons = pcall(require, "nvim-web-devicons")

  if not ok then
    return fallback_icon()
  end

  local icon, highlight = devicons.get_icon(name, vim.fn.fnamemodify(file_path, ":e"), {
    default = true,
  })

  if icon ~= nil then
    return icon, highlight or "NvimSidebarFileIcon"
  end

  icon, highlight = default_icon(devicons)

  if icon ~= nil then
    return icon, highlight
  end

  return fallback_icon()
end

return M
