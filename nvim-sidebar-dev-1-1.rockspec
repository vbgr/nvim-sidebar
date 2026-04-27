package = "nvim-sidebar-dev"
version = "1-1"

source = {
  url = ".",
}

description = {
  summary = "Development dependencies for nvim-sidebar",
  license = "MIT",
}

dependencies = {
  "lua >= 5.1, < 5.2",
  "luacov",
}

build = {
  type = "none",
}
