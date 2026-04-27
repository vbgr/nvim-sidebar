local config = require("nvim-sidebar.config")

local M = {}

function M.file(file_path, name)
  if not config.options.icons.devicons then
    return config.options.icons.file, "NvimSidebarFileIcon"
  end

  local ok, devicons = pcall(require, "nvim-web-devicons")

  if not ok then
    return config.options.icons.file, "NvimSidebarFileIcon"
  end

  local icon, highlight = devicons.get_icon(name, vim.fn.fnamemodify(file_path, ":e"), {
    default = true,
  })

  return icon or config.options.icons.file, highlight or "NvimSidebarFileIcon"
end

return M
