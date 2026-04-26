local buffer = require("nvim-sidebar.ui.buffer")
local cursor = require("nvim-sidebar.ui.cursor")
local state = require("nvim-sidebar.state")

local M = {}

local ns = vim.api.nvim_create_namespace("nvim-sidebar")

local function target_buffer(mode)
  if mode == "full" then
    return state.full.bufnr
  end

  return state.sidebar.bufnr
end

local function apply_highlights(bufnr, highlights)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  for _, highlight in ipairs(highlights or {}) do
    if highlight.virt_text ~= nil then
      vim.api.nvim_buf_set_extmark(bufnr, ns, highlight.line - 1, 0, {
        virt_text = {
          {
            highlight.virt_text,
            highlight.group,
          },
        },
        virt_text_pos = "right_align",
      })
    else
      vim.api.nvim_buf_add_highlight(
        bufnr,
        ns,
        highlight.group,
        highlight.line - 1,
        highlight.col_start or 0,
        highlight.col_end or -1
      )
    end
  end
end

function M.render_source(source, mode)
  state.render_mode = mode

  local bufnr = target_buffer(mode)
  local name = type(source.display_name) == "function" and source.display_name() or source.name
  local result = source.render({
    mode = mode,
  })

  buffer.set_name(bufnr, name)
  buffer.set_lines(bufnr, result.lines)
  state.set_items(bufnr, result.items)
  apply_highlights(bufnr, result.highlights)
  cursor.restore(bufnr)
end

return M
