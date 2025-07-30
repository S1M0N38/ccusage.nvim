---@class CCUsage.Data
local M = {}

---Get formatter context with unified error handling
---@return CCUsage.FormatterContext context with data/stats as nil if unavailable
M.get_formatter_context = function()
  local cli = require("ccusage.cli")
  local utils = require("ccusage.utils")

  ---@type CCUsage.FormatterContext
  local context = {
    data = nil,
    stats = nil,
  }

  -- Check if CLI is available
  if not cli.is_available() then
    return context
  end

  -- Get ccusage data
  local blocks_data = cli.ccusage_blocks()
  if not blocks_data or not blocks_data.blocks or #blocks_data.blocks == 0 then
    return context
  end

  -- Set data
  context.data = blocks_data

  -- Compute stats from blocks data
  local stats = utils.compute_stats(blocks_data)
  if stats then
    context.stats = stats
  end

  return context
end

return M
