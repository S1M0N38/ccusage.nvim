-- ccusage component for lualine.nvim
-- Displays Claude Code usage information in the statusline

local data = require("ccusage.data")
local config = require("ccusage.config")

---@return string formatted ccusage information for lualine display
local function ccusage_component()
  -- Get formatter context with unified error handling
  local context = data.get_formatter_context()

  -- Handle errors with appropriate statusline messages
  if not context.data then
    return "ccusage: not found"
  end

  if not context.stats then
    return "ccusage: no stats"
  end

  -- Use the configured formatter function to display the data
  local formatter_fn = config.options.formatter
  if type(formatter_fn) == "function" then
    local result = formatter_fn(context)
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
