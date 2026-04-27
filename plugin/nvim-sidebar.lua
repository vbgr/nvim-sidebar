if vim.g.loaded_nvim_sidebar == 1 then
  return
end

vim.g.loaded_nvim_sidebar = 1

require("nvim-sidebar.commands").setup()
