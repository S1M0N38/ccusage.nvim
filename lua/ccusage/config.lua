---@class CCUsage.Config
local M = {}

---@class CCUsage.DefaultOptions
M.defaults = {
  ccusage_cmd = "ccusage",
  formatter = require("ccusage.formatters.default"),
}

---@type CCUsage.Options
M.options = M.defaults

---Extend the defaults options table with the user options
---@param opts? CCUsage.UserOptions: plugin options
---@return nil
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
