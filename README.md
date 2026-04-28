# nvim-sidebar

`nvim-sidebar` is a small Neovim plugin for keeping files and buffers visible
in a side window while staying close to Vim's native window and buffer model.

## Motivation

Vim already has a strong buffer workflow: buffers are edited in normal windows,
and buffer names are reported by the native UI at the bottom when you switch or
open them. This plugin does not try to replace that model with a tabline-like
interface or a heavily configured bufferline setup.

Instead, it gives buffers and files a simple spatial index in a sidebar. For
some workflows, a vertical buffer list is easier to scan than many horizontal
tabs, especially once tab labels start scrolling or truncating. The files source
follows the same idea: keep the file explorer in a side window for quick local
navigation, and use the full-window tree when a deeper project traversal needs
more room.

The result is intentionally plain: native Vim UX, scratch buffers, normal
commands, buffer-local mappings, and no visual framework to maintain.

## Features

- Files sidebar rooted at `vim.fn.getcwd()`
- Buffers sidebar for loaded, listed buffers
- Full-window file tree with optional metadata columns
- Search, locate, open, collapse, copy, cut, paste, trash, yank, duplicate, and
  rename actions for files
- Search, locate, open, and yank actions for buffers
- Optional `nvim-web-devicons` integration
- Optional lualine extension for sidebar statuslines
- Plain Neovim Lua test suite with Docker coverage support

## Setup

Install the plugin with your plugin manager, then configure it from Lua if the
defaults are not enough:

```lua
require("nvim-sidebar").setup({
  width = 40,
  side = "left",
  padding_left = 2,
  default_source = "files",
  sources = {
    "files",
    "buffers",
  },
})
```

The plugin registers user commands automatically from `plugin/nvim-sidebar.lua`,
so explicit setup is optional when you want the defaults.

### Lualine

The plugin ships a lualine extension. Enable it if you want lualine to render a
sidebar-specific statusline instead of the normal editor statusline:

```lua
require("lualine").setup({
  extensions = {
    "nvim-sidebar",
  },
})
```

The extension shows the current directory path for file views and `buffers` for
the buffers source.

## Commands

```vim
:NvimSidebar [files|buffers]
:NvimSidebarToggle [files|buffers]
:NvimSidebarRefresh
:NvimSidebarLocate [files|buffers]
:NvimSidebarTree
```

- `NvimSidebar` opens the requested source, or `default_source`.
- `NvimSidebarToggle` closes the current sidebar or switches source.
- `NvimSidebarRefresh` re-renders visible sidebar/full-tree views.
- `NvimSidebarLocate` opens the source and positions the cursor on the current
  file or buffer.
- `NvimSidebarTree` opens the files source in the current window as a full tree.

Lua API equivalents:

```lua
local sidebar = require("nvim-sidebar")

sidebar.open("files")
sidebar.open("buffers")
sidebar.toggle("files")
sidebar.focus()
sidebar.refresh()
sidebar.locate("files")
sidebar.open_full_tree()
sidebar.close()
```

## Buffers View

The buffers source is a flat sidebar list. Each row contains the buffer number,
an optional file icon, the file name, and a modified marker when applicable.
Duplicated file names include their parent directory, and the current editor
buffer is highlighted while focus is outside the buffers sidebar.

Default buffer actions:

- `o`: open selected buffer
- `<Tab>`: move to next buffer and show it in its editor window
- `<S-Tab>`: move to previous buffer and show it in its editor window
- `/`: live fuzzy search buffers
- `<Esc>`: clear search
- `y`: yank selected buffer names
- `L`: locate current editor buffer
- `r`: refresh
- `q`: close

Visual mode is supported for buffer-name yanking.

## Files View

The files source renders a hierarchical tree rooted at the current working
directory.

File rows include an optional icon, file name, opened-buffer marker, and git
status marker. Directory rows include the configured expanded/collapsed marker
and directory name. Directories are sorted before files.

Default file actions:

- `o`: open file or expand/collapse directory
- `O`: collapse directory or parent directory
- `/`: live fuzzy search visible entries
- `<Esc>`: clear search
- `a`: create file
- `A`: create directory
- `d`: trash selected paths
- `c`: copy selected paths
- `x`: cut selected paths
- `p`: paste copied/cut paths
- `y`: yank basenames
- `Y`: yank paths relative to `vim.fn.getcwd()`
- `D`: duplicate selected paths
- `R`: rename selected path
- `L`: locate current editor file
- `r`: refresh
- `q`: close

Visual mode is supported for trash, copy, cut, yank, and duplicate actions.
When paste targets an existing path, the pasted item is written to a unique
`copy` name instead of overwriting the existing file or directory.

### Search

Search uses Neovim's native `/` command-line UI. Results refresh while you type,
so pressing Enter is optional and only keeps the current filtered results.
Pressing `<Esc>` or `<C-c>` while the search command-line is active clears the
query and restores the unfiltered view. The normal-mode `<Esc>` mapping clears
an existing search after the command-line has already closed.

File search filters the currently rendered tree. It does not expand collapsed
directories while searching.

### Full Tree

The full tree view renders the files source in the current window instead of a
side split. It is useful for deeper navigation where a narrow sidebar is too
small.

Full tree rows can include metadata columns:

- `size`
- `type`
- `modified`

Configure the order with `tree.full_columns`.

## Configuration

Common options:

```lua
{
  width = 40,
  side = "left",
  padding_left = 2,
  default_source = "files",
  sources = { "files", "buffers" },

  keymaps = {
    open = "o",
    collapse = "O",
    search = "/",
    clear_search = "<Esc>",
    new_file = "a",
    new_directory = "A",
    trash = "d",
    copy = "c",
    cut = "x",
    paste = "p",
    yank_name = "y",
    yank_path = "Y",
    duplicate = "D",
    rename = "R",
    locate = "L",
    next_buffer = "<Tab>",
    previous_buffer = "<S-Tab>",
    refresh = "r",
    close = "q",
  },

  tree = {
    indent_width = 2,
    indent_markers = false,
    exclude_patterns = {
      "^%.git$",
      "^%.DS_Store$",
      "%.pyc$",
      "^__pycache__$",
      "^node_modules$",
    },
    directory_size = "-/-",
    directory_type = "Folder",
    full_columns = { "size", "type", "modified" },
    date_format = "%Y-%m-%d %H:%M",
  },

  search = {
    case_sensitive = false,
  },

  trash_cmd = nil,
}
```

### Excluding Files

`tree.exclude_patterns` is a list of Lua patterns matched against each entry
basename, not the full path.

```lua
require("nvim-sidebar").setup({
  tree = {
    exclude_patterns = {
      "^%.git$",
      "^dist$",
      "%.log$",
    },
  },
})
```

### Trash Command

Trash is disabled until `trash_cmd` is configured. The command can be a string
or a list. The selected path is appended as the final argument.

```lua
require("nvim-sidebar").setup({
  trash_cmd = { "trash" },
})
```

## Development

### Tests

Run the plain headless test suite:

```sh
nvim --headless -u NONE -i NONE -l tests/all.lua
```

The suite is plain Neovim Lua, not Busted or Plenary. Tests live under:

- `tests/unit/`
- `tests/buffers/`
- `tests/files/`

#### Coverage

Install development dependencies into the local LuaRocks tree:

```sh
luarocks --lua-version=5.1 --tree .luarocks make --only-deps nvim-sidebar-dev-1-1.rockspec
```

Run the full local test/coverage script:

```sh
./run-tests.sh
```

Coverage artifacts are written to:

- `coverage/luacov.report.out`
- `coverage/luacov.stats.out`
- `coverage/index.html`

`tests/all.lua` remains the canonical non-coverage runner.

### Docker

Use the Alpine-based Docker image when you want the full test environment to be
independent from the host Lua, LuaRocks, Neovim, and trash-command setup:

```sh
docker build -t nvim-sidebar-test .
```

The image build installs Lua 5.1, LuaRocks 5.1, Neovim, `trash-cli`, project
LuaRocks dependencies, then runs:

```sh
./run-tests.sh
```

To rerun the suite and write coverage artifacts back to the host:

```sh
mkdir -p coverage
docker run --rm \
  -v "$PWD/coverage:/src/coverage" \
  nvim-sidebar-test
```
