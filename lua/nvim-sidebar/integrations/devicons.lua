local config = require("nvim-sidebar.config")

local M = {}

function M.file(file_path, name)
  if not config.options.icons.devicons then
    return config.options.icons.file
  end

  local ok, devicons = pcall(require, "nvim-web-devicons")

  if not ok then
    return config.options.icons.file
  end

  local icon = devicons.get_icon(name, vim.fn.fnamemodify(file_path, ":e"), {
    default = true,
  })

  return icon or config.options.icons.file
end

return M
