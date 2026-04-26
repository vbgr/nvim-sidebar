local config = require("nvim-sidebar.config")

local M = {}

function M.match(value, query)
  if query == nil or query == "" then
    return true
  end

  value = value or ""

  if not config.options.search.case_sensitive then
    value = value:lower()
    query = query:lower()
  end

  local value_index = 1

  for query_index = 1, #query do
    local char = query:sub(query_index, query_index)
    local found = value:find(char, value_index, true)

    if found == nil then
      return false
    end

    value_index = found + 1
  end

  return true
end

return M
