local M = {}

local registered = false

local function complete_sources()
  return require("nvim-sidebar.sources").names()
end

function M.setup()
  if registered then
    return
  end

  registered = true

  vim.api.nvim_create_user_command("NvimSidebar", function(command)
    local source = command.args ~= "" and command.args or nil
    require("nvim-sidebar").open(source)
  end, {
    nargs = "?",
    complete = complete_sources,
    desc = "Open nvim-sidebar",
  })

  vim.api.nvim_create_user_command("NvimSidebarToggle", function(command)
    local source = command.args ~= "" and command.args or nil
    require("nvim-sidebar").toggle(source)
  end, {
    nargs = "?",
    complete = complete_sources,
    desc = "Toggle nvim-sidebar",
  })

  vim.api.nvim_create_user_command("NvimSidebarRefresh", function()
    require("nvim-sidebar").refresh()
  end, {
    desc = "Refresh nvim-sidebar",
  })

  vim.api.nvim_create_user_command("NvimSidebarLocate", function(command)
    local source = command.args ~= "" and command.args or nil
    require("nvim-sidebar").locate(source)
  end, {
    nargs = "?",
    complete = complete_sources,
    desc = "Locate current file or buffer in nvim-sidebar",
  })

  vim.api.nvim_create_user_command("NvimSidebarTree", function()
    require("nvim-sidebar").open_full_tree()
  end, {
    desc = "Open full filesystem tree",
  })
end

return M
