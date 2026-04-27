local M = {}

function M.setup()
  vim.api.nvim_set_hl(0, "NvimSidebarFileIcon", {
    link = "Normal",
    default = true,
  })
  vim.api.nvim_set_hl(0, "NvimSidebarDirectory", {
    link = "Directory",
    default = true,
  })
  vim.api.nvim_set_hl(0, "NvimSidebarModified", {
    link = "WarningMsg",
    default = true,
  })
  vim.api.nvim_set_hl(0, "NvimSidebarCurrentBuffer", {
    link = "CursorLine",
    default = true,
  })
  vim.api.nvim_set_hl(0, "NvimSidebarGitModified", {
    link = "WarningMsg",
    default = true,
  })
  vim.api.nvim_set_hl(0, "NvimSidebarGitAdded", {
    link = "String",
    default = true,
  })
  vim.api.nvim_set_hl(0, "NvimSidebarGitUntracked", {
    link = "Comment",
    default = true,
  })
  vim.api.nvim_set_hl(0, "NvimSidebarSearch", {
    link = "Search",
    default = true,
  })
end

return M
