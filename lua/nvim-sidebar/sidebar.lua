local M = {}

function M.open(source_name)
  return require("nvim-sidebar").open(source_name)
end

return M
