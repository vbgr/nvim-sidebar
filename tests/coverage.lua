local root = vim.fn.getcwd()

package.path = table.concat({
  root .. "/.luarocks/share/lua/5.1/?.lua",
  root .. "/.luarocks/share/lua/5.1/?/init.lua",
  package.path,
}, ";")
package.cpath = table.concat({
  root .. "/.luarocks/lib/lua/5.1/?.so",
  package.cpath,
}, ";")

vim.fn.mkdir("coverage", "p")
vim.fn.delete("coverage/luacov.stats.out")
vim.fn.delete("coverage/luacov.report.out")
vim.fn.delete("coverage/missing-lines.txt")

local ok, runner = pcall(require, "luacov.runner")

if not ok then
  error(
    "LuaCov is not installed. Run: luarocks --lua-version=5.1 --tree .luarocks make --only-deps nvim-sidebar-dev-1-1.rockspec"
  )
end

runner.init(".luacov")

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    runner.shutdown()
    runner.run_report()
  end,
})

require("tests.all")
