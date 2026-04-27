local config = require("nvim-sidebar.config")

local M = {}

local registry = {
  buffers = require("nvim-sidebar.sources.buffers"),
  files = require("nvim-sidebar.sources.files"),
}

function M.get(name)
  return registry[M.resolve(name)]
end

function M.resolve(name)
  if name ~= nil and registry[name] ~= nil then
    return name
  end

  if registry[config.options.default_source] ~= nil then
    return config.options.default_source
  end

  return config.options.sources[1]
end

function M.names()
  local names = {}

  for _, source in ipairs(config.options.sources) do
    if registry[source] ~= nil then
      table.insert(names, source)
    end
  end

  return names
end

return M
