local state = require("nvim-sidebar.state")

local M = {}

function M.prompt(callback)
  vim.ui.input({
    prompt = "Search: ",
    default = state.search.query,
  }, function(input)
    if input == nil then
      return
    end

    state.search.query = input

    if callback ~= nil then
      callback()
    end
  end)
end

return M
