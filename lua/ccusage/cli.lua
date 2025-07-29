---@class CCUsage.CLI
local M = {}

local config = require("ccusage.config")

-- Simple cache
local cache = {
  data = nil,
  last_update = 0,
  availability = nil,
}

---Simple jobstart to get ccusage blocks
---@return CCUsage.Data|nil
M.ccusage_blocks = function()
  -- Check cache first (5 second cache)
  ---@diagnostic disable-next-line: undefined-field
  local now = vim.uv.now()

  if cache.data and (now - cache.last_update) < 5000 then
    return cache.data
  end

  -- Update timestamp immediately to prevent multiple jobs
  cache.last_update = now

  local base_cmd = config.options.ccusage_cmd

  vim.fn.jobstart({ base_cmd, "blocks", "--json", "--offline" }, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if #data > 0 then
        local result = table.concat(data, "\n")
        local ok, parsed = pcall(vim.json.decode, result)
        if ok then
          cache.data = parsed
        end
      end
    end,
  })

  return cache.data
end

---Check if ccusage CLI is available
---@return boolean
M.is_available = function()
  if cache.availability ~= nil then
    return cache.availability
  end

  local base_cmd = config.options.ccusage_cmd
  local found = false

  vim.fn.jobstart({ base_cmd, "--version" }, {
    on_stdout = function(_, data, _)
      if #data > 0 and data[1] ~= "" then
        found = true
      end
    end,
    on_exit = function(_, exit_code, _)
      cache.availability = (exit_code == 0 and found)
    end,
  })

  return cache.availability or false
end

---Force refresh
---@return CCUsage.Data|nil
M.refresh_blocks = function()
  cache.data = nil
  cache.last_update = 0
  return M.ccusage_blocks()
end

return M
