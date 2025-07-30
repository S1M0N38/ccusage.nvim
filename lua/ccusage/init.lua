---@class CCUsage.Plugin
local M = {}

---Setup the ccusage plugin
---@param opts? CCUsage.UserOptions plugin options
---@return nil
M.setup = function(opts)
  require("ccusage.config").setup(opts)
end

return M
