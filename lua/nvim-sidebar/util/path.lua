local M = {}

function M.normalize(value)
  if value == nil or value == "" then
    return ""
  end

  value = value:gsub("\\", "/")

  if #value > 1 then
    value = value:gsub("/+$", "")
  end

  return value
end

function M.join(...)
  local parts = {}

  for _, part in ipairs({ ... }) do
    if part ~= nil and part ~= "" then
      table.insert(parts, tostring(part))
    end
  end

  local result = table.concat(parts, "/"):gsub("/+", "/")

  if parts[1] ~= nil and tostring(parts[1]):sub(1, 1) == "/" and result:sub(1, 1) ~= "/" then
    result = "/" .. result
  end

  return M.normalize(result)
end

function M.basename(value)
  value = M.normalize(value)
  return value:match("([^/]+)$") or value
end

function M.dirname(value)
  value = M.normalize(value)

  local directory = value:match("^(.*)/[^/]+$")

  if directory == nil or directory == "" then
    return "."
  end

  return directory
end

function M.relative(root, value)
  root = M.normalize(root)
  value = M.normalize(value)

  if value == root then
    return "."
  end

  if value:sub(1, #root + 1) == root .. "/" then
    return value:sub(#root + 2)
  end

  return value
end

function M.is_descendant(root, value)
  root = M.normalize(root)
  value = M.normalize(value)

  return value == root or value:sub(1, #root + 1) == root .. "/"
end

function M.extension(value)
  return value:match("%.([^%.]+)$") or ""
end

return M
