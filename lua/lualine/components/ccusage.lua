-- ccusage component for lualine.nvim
-- Displays Claude Code usage information in the statusline

local cli = require("ccusage.cli")
local config = require("ccusage.config")

---@return string: formatted ccusage information for lualine display
local function ccusage_component()
  -- Check if CLI is available
  local cli_available = cli.is_available()
  if not cli_available then
    return "ccusage: not found"
  end

  -- Get ccusage data
  local blocks_data = cli.ccusage_blocks()
  if not blocks_data then
    return "ccusage: loading..."
  end

  -- Compute stats from blocks data
  local utils = require("ccusage.utils")
  local stats = utils.compute_stats(blocks_data)

  if not stats then
    return "ccusage: no stats"
  end

  -- Use the configured formatter function to display the data
  local formatter_fn = config.options.formatter
  if type(formatter_fn) == "function" then
    local result = formatter_fn(stats)
    if result then
      return result
    else
      return "" -- Hide component when formatter function returns nil
    end
  end

  -- Fallback if no formatter function is configured (shouldn't happen)
  return "ccusage: no formatter"
end

return ccusage_component
