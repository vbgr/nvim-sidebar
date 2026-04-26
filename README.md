# nvim-sidebar

Neovim Sidebar

## Description

Neovim plugin to render in sidebar several sources:

- File tree
- Buffers
- *Some other in the future*

Some sources (like filesystem tree) can be rendered in a not listed buffer,
full width, with additional details.

The plugin integrates with Dev Icons (if the plugin is installed).

### Buffers

Buffers sidebar is flat, each item contains the following information:

1. Buffer number
2. File icon
3. File name
4. Small circle if buffer has been modified

Current buffer is always highlighted.

#### Functionality

**Locate**

Open buffers view, current buffer must be highlighted by default.

**Search**

Triggered by `/`. Fuzzy search that limits buffers list.

**Yank**

Yank buffer file name.

### File tree

Filesystem sidebar is hierarchical, each file item contains:

1. File icon
2. File name
3. In the right side circle may be added that represents git status:
  + Red - if file is under git and has been modified
  + Green - if file is new and was added to git
  + Nothing - if file is under git and is committed
  + Very lightweight transparent gray - if file is not under git but .git directory exists
4. Tiny lightweight circle indicatign that the file is opened in a buffer.

Each folder item contains:

1. Folder indicator (expanded/collapsed), the sign is defined in config
2. Folder name

The layout is classical hierarchical.
Optional ident symbols are can be rendered like in `tree` command output.
Directories are sorted always on top.

In case of the full buffer view additional information is rendered for file items:

* Size
* Type (extension)
* Last modified date

In case of the full buffer view additional information is rendered for directory items:

* -- (instead of size), the actual string is defined by the config param
* Folder (directory type), exact values is defined by the config param
* Last modified date

The order of these columns may be defined via configuration parameter.

File tree is rendered in the current neovim workding directory `vim.fn.getcwd()`.

#### Functionality

**Locate**

Locate current file in the tree and expand if needed all the parent directories.

**Search**

Same as for buffers. Search only in expanded directorries.

**Expand**

Expand directory. Key is confirurable, default is `o`. If cursor is positioned on file, opens file in new buffer, if file is already opened just open its buffer.

**Collapse**

Collapse directory. If the current item is file, the directory is collapsed,
if the current item is collapsed directory the parent directory is collapsed,
in both these cases cursor is poitioned to the parent directory.

When sidebar is opened buffers or filesystem is rendered as it was before it
was closed, for filesystem expand/collapse is preserved.
When filesystem directory is rendered first time all directorries are collapsed.

Expand/collapse is not preserved between neovim runs, each process has its own
independent state.

Collapse key is configurable, default is `O`.

**New File**

Add new file under the directory. Parent directory is determined by closed
directory in the rendered tree.

Key is configurable, default is `a`.

**New directory**

Add new directory. Parent directory is determined by closed directory in the
rendered tree.

Key is configurable, default is `A`.

**Trash**

`trash` command must be defined in config parameters.

Supports visual selection. For directories recursion behavior.

**Copy/Cut/Paste**

Supports visual selection.

**Yank name**

Yank file name.

**Yank path**

Yank path (relative to `vim.fn.getcwd()`).

**Duplicate**

Like in Mac OS - create entity (deep copy for directory) with name "{original name} copy"
