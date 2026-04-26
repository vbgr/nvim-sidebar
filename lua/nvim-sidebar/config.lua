local M = {}

M.defaults = {
  width = 30,
  side = "left",
  default_source = "files",
  sources = {
    "files",
    "buffers",
  },
  icons = {
    devicons = true,
    file = "",
    folder_closed = "+",
    folder_open = "-",
    modified = "*",
    buffer_open = "o",
    git_modified = "M",
    git_added = "A",
    git_untracked = "?",
  },
  keymaps = {
    open = "o",
    collapse = "O",
    search = "/",
    new_file = "a",
    new_directory = "A",
    trash = "d",
    copy = "c",
    cut = "x",
    paste = "p",
    yank_name = "y",
    yank_path = "Y",
    duplicate = "D",
    locate = "L",
    refresh = "r",
    close = "q",
  },
  tree = {
    indent_width = 2,
    indent_markers = false,
    ignored = {
      ".git",
    },
    directory_size = "--",
    directory_type = "Folder",
    full_columns = {
      "size",
      "type",
      "modified",
    },
    date_format = "%Y-%m-%d %H:%M",
  },
  search = {
    case_sensitive = false,
  },
  trash_cmd = nil,
}

M.options = vim.deepcopy(M.defaults)

local valid_sources = {
  buffers = true,
  files = true,
}

local function validate_options(opts)
  if opts.side ~= "left" and opts.side ~= "right" then
    error("nvim-sidebar: side must be 'left' or 'right'", 3)
  end

  if type(opts.width) ~= "number" or opts.width < 1 then
    error("nvim-sidebar: width must be a positive number", 3)
  end

  for _, source in ipairs(opts.sources) do
    if not valid_sources[source] then
      error("nvim-sidebar: unknown source '" .. source .. "'", 3)
    end
  end

  if not valid_sources[opts.default_source] then
    error("nvim-sidebar: unknown default_source '" .. tostring(opts.default_source) .. "'", 3)
  end
end

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  validate_options(M.options)
  return M.options
end

return M
