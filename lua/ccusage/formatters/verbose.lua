---@class VerboseFormatter
local M = {}

---Format tokens with K/M suffixes
---@param tokens number
---@return string
local function format_tokens(tokens)
  if tokens >= 1000000 then
    return string.format("%.1fM", tokens / 1000000)
  elseif tokens >= 1000 then
    return string.format("%.1fK", tokens / 1000)
  else
    return tostring(tokens)
  end
end

---Format cost with appropriate precision
---@param cost number
---@return string
local function format_cost(cost)
  if cost < 0.01 then
    return string.format("$%.4f", cost)
  else
    return string.format("$%.2f", cost)
  end
end

---Format timestamp to readable date/time
---@param timestamp number?
---@return string
local function format_time(timestamp)
  if not timestamp or timestamp == 0 then
    return "Unknown"
  end
  return os.date("%Y-%m-%d %H:%M:%S", timestamp) ---@diagnostic disable-line: return-type-mismatch
end

---Format detailed usage statistics for verbose display
---@param context CCUsage.FormatterContext Context with data and stats
---@return string? Formatted verbose statistics string, or nil if data unavailable
M.format = function(context)
  if not context or not context.data or not context.stats then
    return nil
  end

  local blocks_data = context.data or {}
  local stats = context.stats or {}

  -- Get the most recent block for additional details
  local last_block = blocks_data.blocks[#blocks_data.blocks]

  -- Build detailed statistics message
  local lines = {}
  table.insert(lines, "Claude Code Usage Statistics")
  table.insert(lines, "")

  -- Session Info
  table.insert(lines, "Session Information:")
  table.insert(lines, string.format("   Start: %s", format_time(stats.start_time)))
  if stats.end_time > 0 then
    table.insert(lines, string.format("   End: %s", format_time(stats.end_time)))
  else
    table.insert(lines, "   Status: Active")
  end
  table.insert(lines, "")

  -- Token Usage
  table.insert(lines, "Token Usage:")
  table.insert(lines, string.format("   Current: %s tokens", format_tokens(stats.tokens)))
  table.insert(lines, string.format("   Limit: %s tokens", format_tokens(stats.max_tokens)))
  table.insert(lines, string.format("   Usage: %.1f%%", stats.usage_ratio * 100))

  -- Add detailed token breakdown if available
  local token_counts = last_block.tokenCounts
  if
    token_counts and (token_counts.inputTokens or token_counts.outputTokens or token_counts.cacheCreationInputTokens)
  then
    table.insert(lines, "")
    table.insert(lines, "   Breakdown:")
    if token_counts.inputTokens then
      table.insert(lines, string.format("     Input: %s", format_tokens(token_counts.inputTokens)))
    end
    if token_counts.outputTokens then
      table.insert(lines, string.format("     Output: %s", format_tokens(token_counts.outputTokens)))
    end
    if token_counts.cacheCreationInputTokens and token_counts.cacheCreationInputTokens > 0 then
      table.insert(
        lines,
        string.format("     Cache Creation: %s", format_tokens(token_counts.cacheCreationInputTokens))
      )
    end
    if token_counts.cacheReadInputTokens and token_counts.cacheReadInputTokens > 0 then
      table.insert(lines, string.format("     Cache Read: %s", format_tokens(token_counts.cacheReadInputTokens)))
    end
  end
  table.insert(lines, "")

  -- Cost Information
  if stats.cost > 0 then
    table.insert(lines, "Cost Information:")
    table.insert(lines, string.format("   Current Session: %s", format_cost(stats.cost)))
    table.insert(lines, "")
  end

  -- Time Progress
  if stats.time_ratio > 0 then
    table.insert(lines, "Session Progress:")
    table.insert(lines, string.format("   Time: %.1f%%", stats.time_ratio * 100))
    table.insert(lines, "")
  end

  -- Usage Status and Warnings
  if stats.usage_ratio > 1.0 then
    table.insert(lines, "Token limit exceeded!")
  elseif stats.usage_ratio >= 0.8 then
    table.insert(lines, "Approaching token limit")
  else
    table.insert(lines, "Usage within normal limits")
  end

  return table.concat(lines, "\n")
end

return M.format
