---@class CCUsage.Utils
local M = {}

---Check if a command exists
---@param cmd string: command to check
---@return boolean?: true if command exists, false/nil if not
M.command_exists = function(cmd)
  local handle = io.popen("command -v " .. cmd .. " 2>/dev/null")
  if not handle then
    return false
  end

  local result = handle:read("*a")
  local success = handle:close()

  return success and result and result ~= ""
end

---Get ccusage version
---@return string|nil: version string or nil if not available
M.get_ccusage_version = function()
  local handle = io.popen("ccusage --version 2>/dev/null")
  if not handle then
    return nil
  end

  local result = handle:read("*a")
  local success = handle:close()

  if success and result then
    return result:gsub("\n", "")
  end

  return nil
end

---Convert ISO 8601 UTC timestamp to Lua time table
---@param str string: ISO 8601 timestamp string (e.g., "2025-07-29T06:00:00.000Z")
---@return number?: Unix timestamp or nil on error
M.parse_utc_iso8601 = function(str)
  if not str then
    return nil
  end

  local year, month, day, hour, min, sec = str:match("(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
  if not year then
    return nil
  end

  return os.time({
    year = tonumber(year), ---@diagnostic disable-line: assign-type-mismatch
    month = tonumber(month), ---@diagnostic disable-line: assign-type-mismatch
    day = tonumber(day), ---@diagnostic disable-line: assign-type-mismatch
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec),
    isdst = false,
  })
end

---Convert UTC time to local time string
---@param utc_time number: Unix timestamp in UTC
---@param format? string: Optional format string (defaults to "%H")
---@return string: Formatted local time string
M.utc_to_local = function(utc_time, format)
  format = format or "%H"
  local utc_offset = os.difftime(os.time(), os.time(os.date("!*t"))) ---@diagnostic disable-line: param-type-mismatch
  local datatime_str = os.date(format, utc_time + utc_offset)
  assert(type(datatime_str) == "string", "utc_to_local: datatime_str is not a string")
  return datatime_str
end

---Convert ISO 8601 UTC timestamp string directly to local time string
---@param iso_str? string: ISO 8601 timestamp string
---@param format? string: Optional format string (defaults to "%H")
---@return string?: Formatted local time string or nil on error
M.iso_to_local = function(iso_str, format)
  if not iso_str then
    return nil
  end

  local utc_time = M.parse_utc_iso8601(iso_str)
  if not utc_time then
    return nil
  end

  return M.utc_to_local(utc_time, format)
end

---Compute stats from blocks data
---@param blocks_data CCUsage.Data: blocks data from ccusage CLI
---@return CCUsage.Stats|nil: computed stats or nil if no data
M.compute_stats = function(blocks_data)
  if not blocks_data or not blocks_data.blocks or #blocks_data.blocks == 0 then
    return nil
  end

  -- Use the last block (most recent) regardless of active status
  local last_block = blocks_data.blocks[#blocks_data.blocks]

  -- Calculate max tokens allowed for block based on previous blocks
  local max_tokens = 0
  for _, b in ipairs(blocks_data.blocks) do
    if not b.isGap and b.totalTokens then
      max_tokens = math.max(max_tokens, b.totalTokens)
    end
  end

  -- If no previous blocks, use current block's projection or a default
  if max_tokens == 0 then
    if last_block.projection and last_block.projection.totalTokens then
      max_tokens = last_block.projection.totalTokens
    else
      max_tokens = 20000000 -- Default 20M tokens
    end
  end

  local tokens = last_block.totalTokens or 0
  local usage_ratio = tokens / max_tokens
  local cost = last_block.costUSD or 0

  -- Convert ISO times to unix epoch UTC
  local start_time = M.parse_utc_iso8601(last_block.startTime) or 0
  local end_time = M.parse_utc_iso8601(last_block.endTime) or 0

  -- Calculate time ratio (session progress)
  local time_ratio = 0
  if start_time > 0 then
    local current_time = os.time()
    local elapsed = current_time - start_time

    -- For active sessions, estimate based on typical session length (1 hour)
    -- For completed sessions, use actual duration
    local total_duration
    if end_time > 0 then
      total_duration = end_time - start_time
    else
      -- Estimate typical session length as 1 hour (3600 seconds)
      total_duration = math.max(elapsed, 3600)
    end

    if total_duration > 0 then
      time_ratio = math.min(elapsed / total_duration, 1.0) -- Cap at 100%
    end
  end

  return {
    max_tokens = max_tokens,
    tokens = tokens,
    usage_ratio = usage_ratio,
    start_time = start_time,
    end_time = end_time,
    cost = cost,
    time_ratio = time_ratio,
  }
end

return M
