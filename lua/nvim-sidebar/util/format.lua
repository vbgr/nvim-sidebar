local M = {}

function M.size(bytes)
  if bytes == nil then
    return ""
  end

  local units = {
    "B",
    "K",
    "M",
    "G",
  }
  local size = bytes
  local unit = 1

  while size >= 1024 and unit < #units do
    size = size / 1024
    unit = unit + 1
  end

  if unit == 1 then
    return string.format("%d%s", size, units[unit])
  end

  return string.format("%.1f%s", size, units[unit])
end

function M.mtime(mtime, date_format)
  if mtime == nil then
    return ""
  end

  local seconds = type(mtime) == "table" and mtime.sec or mtime
  return os.date(date_format, seconds)
end

return M
