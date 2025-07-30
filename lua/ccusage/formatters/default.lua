---Default formatter for ccusage lualine component
---@param context CCUsage.FormatterContext formatter context with data and stats
---@return string|nil formatted display string or nil to hide component
return function(context)
  if not context or not context.stats then
    return nil
  end

  local stats = context.stats

  -- Calculate proximity to limit (80% threshold for "near limit")
  local is_near_limit = stats.usage_ratio >= 0.8
  local is_limit_exceeded = stats.usage_ratio > 1.0

  -- Format time ratio
  local time_ratio_str = string.format("%.0f%%%%", stats.time_ratio * 100)

  -- Format usage ratio
  local usage_ratio_str = string.format("%.0f%%%%", stats.usage_ratio * 100)

  -- Build display components
  local components = {}
  table.insert(components, "time")
  table.insert(components, time_ratio_str)
  table.insert(components, "| tok")
  table.insert(components, usage_ratio_str)

  local display_text = table.concat(components, " ")

  -- Return with color based on token usage
  if is_limit_exceeded then
    return string.format("%%#DiagnosticError#%s%%*", display_text)
  elseif is_near_limit then
    return string.format("%%#DiagnosticWarn#%s%%*", display_text)
  else
    return display_text -- Default color
  end
end
