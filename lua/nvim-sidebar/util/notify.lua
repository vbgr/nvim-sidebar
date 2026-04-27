local M = {}

local function send(message, level)
  vim.notify("[nvim-sidebar] " .. message, level)
end

function M.warn(message)
  send(message, vim.log.levels.WARN)
end

function M.error(message)
  send(message, vim.log.levels.ERROR)
end

return M
