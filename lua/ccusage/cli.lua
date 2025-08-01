---@class CCUsage.CLI
local M = {}

local config = require("ccusage.config")

-- Simplified cache with 5-second TTL
local cache = {
  blocks = { data = nil, timestamp = 0 },
  availability = { data = nil, timestamp = 0 },
}

local CACHE_TTL = 20000 -- 20 seconds in milliseconds

-- Job state tracking to prevent multiple concurrent jobs
local job_state = {
  blocks = { job_id = nil, pending_callbacks = {}, is_running = false },
  availability = { job_id = nil, pending_callbacks = {}, is_running = false },
}

---Check if cached value is still valid
---@param cache_entry table cache entry with data and timestamp
---@return boolean
local function is_cache_valid(cache_entry)
  if not cache_entry.data then
    return false
  end
  ---@diagnostic disable-next-line: undefined-field
  return (vim.uv.now() - cache_entry.timestamp) < CACHE_TTL
end

---Update cache entry
---@param cache_entry table cache entry to update
---@param data any data to cache
local function update_cache(cache_entry, data)
  cache_entry.data = data
  ---@diagnostic disable-next-line: undefined-field
  cache_entry.timestamp = vim.uv.now()
end

---Queue callback for when job is already running
---@param job_type string either "blocks" or "availability"
---@param callback function callback to queue
local function queue_callback(job_type, callback)
  if callback then
    table.insert(job_state[job_type].pending_callbacks, callback)
  end
end

---Execute all queued callbacks with result
---@param job_type string either "blocks" or "availability"
---@param result any result to pass to callbacks
local function execute_queued_callbacks(job_type, result)
  local callbacks = job_state[job_type].pending_callbacks
  job_state[job_type].pending_callbacks = {}

  for _, callback in ipairs(callbacks) do
    callback(result)
  end
end

---Reset job state when job completes
---@param job_type string either "blocks" or "availability"
local function reset_job_state(job_type)
  job_state[job_type].job_id = nil
  job_state[job_type].is_running = false
end

---Get ccusage blocks data with simple caching
---@param opts? {bypass_cache?: boolean, callback?: fun(data: CCUsage.Data?)}
---@return CCUsage.Data?
M.ccusage_blocks = function(opts)
  opts = opts or {}

  -- Return cached data if valid and not bypassing cache
  if not opts.bypass_cache and is_cache_valid(cache.blocks) then
    if opts.callback then
      opts.callback(cache.blocks.data)
    end
    return cache.blocks.data
  end

  -- If job is already running, queue the callback and return cached data
  if job_state.blocks.is_running then
    queue_callback("blocks", opts.callback)
    return not opts.bypass_cache and cache.blocks.data or nil
  end

  -- Start new job
  job_state.blocks.is_running = true
  local base_cmd = config.options.ccusage_cmd

  job_state.blocks.job_id = vim.fn.jobstart({ base_cmd, "blocks", "--json", "--offline" }, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if #data > 0 then
        local result = table.concat(data, "\n")
        local ok, parsed = pcall(vim.json.decode, result)
        if ok then
          -- Update cache only if not bypassing
          if not opts.bypass_cache then
            update_cache(cache.blocks, parsed)
          end

          -- Execute current callback and all queued callbacks
          if opts.callback then
            opts.callback(parsed)
          end
          execute_queued_callbacks("blocks", parsed)
        end
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        if opts.callback then
          opts.callback(nil)
        end
        execute_queued_callbacks("blocks", nil)
      end
      reset_job_state("blocks")
    end,
  })

  -- Return cached data if available and not bypassing cache
  return not opts.bypass_cache and cache.blocks.data or nil
end

---Check if ccusage CLI is available with simple caching
---@param opts? {bypass_cache?: boolean, callback?: fun(available: boolean)}
---@return boolean
M.is_available = function(opts)
  opts = opts or {}

  -- Return cached result if valid and not bypassing cache
  if not opts.bypass_cache and is_cache_valid(cache.availability) then
    if opts.callback then
      opts.callback(cache.availability.data)
    end
    return cache.availability.data
  end

  -- If job is already running, queue the callback and return cached data
  if job_state.availability.is_running then
    queue_callback("availability", opts.callback)
    return not opts.bypass_cache and (cache.availability.data or false) or false
  end

  -- Start new job
  job_state.availability.is_running = true
  local base_cmd = config.options.ccusage_cmd
  local found = false

  job_state.availability.job_id = vim.fn.jobstart({ base_cmd, "--version" }, {
    on_stdout = function(_, data, _)
      if #data > 0 and data[1] ~= "" then
        found = true
      end
    end,
    on_exit = function(_, exit_code, _)
      local available = (exit_code == 0 and found)
      -- Update cache only if not bypassing
      if not opts.bypass_cache then
        update_cache(cache.availability, available)
      end

      -- Execute current callback and all queued callbacks
      if opts.callback then
        opts.callback(available)
      end
      execute_queued_callbacks("availability", available)
      reset_job_state("availability")
    end,
  })

  -- Return cached value if available and not bypassing cache
  return not opts.bypass_cache and (cache.availability.data or false) or false
end

---Force refresh blocks data
---@return CCUsage.Data?
M.refresh_blocks = function()
  cache.blocks.data = nil
  cache.blocks.timestamp = 0
  return M.ccusage_blocks({ bypass_cache = true })
end

return M
