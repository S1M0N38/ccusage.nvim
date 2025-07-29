---@class CCUsage.Health
local M = {}

local cli = require("ccusage.cli")
local utils = require("ccusage.utils")

--- Check Neovim version compatibility
---@return nil
local function check_neovim_version()
  local version = vim.version()
  local required = { 0, 11, 0 }

  if vim.version.cmp(version, required) >= 0 then
    vim.health.ok(string.format("Neovim version %s (>= 0.11.0)", tostring(version)))
  else
    vim.health.error(
      string.format("Neovim version %s is not supported", tostring(version)),
      string.format("ccusage.nvim requires Neovim >= %s", table.concat(required, ".")),
      "Please upgrade your Neovim installation"
    )
  end
end

--- Validate user configuration options
---@return nil
local function validate_configuration()
  local config = require("ccusage.config")
  local opts = config.options

  -- Test option validation
  local ok, err = pcall(function()
    vim.validate({
      ccusage_cmd = { opts.ccusage_cmd, "string" },
      formatter = { opts.formatter, "function" },
    })
  end)

  if not ok then
    vim.health.error(
      "Invalid configuration options: " .. tostring(err),
      "Check your setup() call in init.lua",
      "Ensure ccusage_cmd is a string and formatter is a function"
    )
    return
  end

  -- Test formatter function with sample data
  local sample_stats = {
    max_tokens = 8192,
    tokens = 1024,
    usage_ratio = 0.125,
    start_time = os.time() - 3600,
    end_time = os.time(),
    cost = 0.05,
    time_ratio = 0.8,
  }

  local format_ok, format_result = pcall(opts.formatter, sample_stats)
  if not format_ok then
    vim.health.error(
      "Formatter function failed with sample data: " .. tostring(format_result),
      "Check your custom formatter implementation",
      "Ensure it handles CCUsage.Stats properly and returns string|nil"
    )
  elseif format_result ~= nil and type(format_result) ~= "string" then
    vim.health.warn(
      "Formatter function returned " .. type(format_result) .. " instead of string|nil",
      "Function should return a string for display or nil to hide component"
    )
  else
    vim.health.ok("Configuration options are valid")
    if format_result then
      vim.health.info("Sample formatter output: " .. format_result)
    end
  end
end

--- Check ccusage CLI availability and version
---@return nil
local function check_ccusage_cli()
  -- Check if ccusage command exists
  if not utils.command_exists(require("ccusage.config").options.ccusage_cmd) then
    vim.health.error(
      "ccusage CLI is not available",
      "Install globally: npm install -g ccusage",
      "Verify installation: ccusage --version"
    )
    return
  end

  -- Get and validate version
  local version = utils.get_ccusage_version()
  if version then
    vim.health.ok("ccusage CLI is available (version: " .. version .. ")")

    -- Test CLI execution
    local test_ok, test_result = pcall(function()
      local handle = io.popen(require("ccusage.config").options.ccusage_cmd .. " --help 2>/dev/null")
      if handle then
        local output = handle:read("*a")
        handle:close()
        return output and #output > 0
      end
      return false
    end)

    if test_ok and test_result then
      vim.health.ok("ccusage CLI executes successfully")
    else
      vim.health.warn(
        "ccusage CLI found but execution test failed",
        "Check CLI permissions and PATH configuration",
        "Try running: " .. require("ccusage.config").options.ccusage_cmd .. " --help"
      )
    end
  else
    vim.health.warn(
      "ccusage CLI found but version could not be determined",
      "CLI may be outdated or corrupted",
      "Try reinstalling: npm install -g ccusage"
    )
  end
end

--- Test ccusage data access and validation
---@return nil
local function check_data_access()
  if not cli.is_available() then
    vim.health.error("Cannot test data access - CLI not available", "Fix CLI issues above first")
    return
  end

  -- Test data retrieval
  local data_ok, blocks_data = pcall(cli.ccusage_blocks)
  if not data_ok then
    vim.health.error(
      "ccusage data retrieval failed: " .. tostring(blocks_data),
      "Check ccusage CLI configuration",
      "Ensure Claude Code has been used to generate usage data"
    )
    return
  end

  if not blocks_data then
    vim.health.warn(
      "ccusage CLI works but returned no data",
      "No usage data found - this is normal for new installations",
      "Usage data will appear after using Claude Code"
    )
    return
  end

  -- Validate data structure
  local structure_ok, structure_err = pcall(function()
    vim.validate({
      blocks = { blocks_data.blocks, "table" },
    })

    if #blocks_data.blocks > 0 then
      local first_block = blocks_data.blocks[1]
      vim.validate({
        id = { first_block.id, "string" },
        startTime = { first_block.startTime, "string" },
        isActive = { first_block.isActive, "boolean" },
        tokenCounts = { first_block.tokenCounts, "table" },
        costUSD = { first_block.costUSD, "number" },
      })
    end
  end)

  if not structure_ok then
    vim.health.error(
      "ccusage data structure validation failed: " .. tostring(structure_err),
      "Data format may have changed or be corrupted",
      "Try updating ccusage CLI: npm install -g ccusage"
    )
    return
  end

  vim.health.ok("ccusage data access working correctly")

  -- Report data details
  local total_blocks = #blocks_data.blocks
  local active_count = 0
  local total_tokens = 0
  local total_cost = 0

  for _, block in ipairs(blocks_data.blocks) do
    if block.isActive then
      active_count = active_count + 1
    end
    if block.tokenCounts then
      local input = block.tokenCounts.inputTokens or 0
      local output = block.tokenCounts.outputTokens or 0
      local cache_create = block.tokenCounts.cacheCreationInputTokens or 0
      local cache_read = block.tokenCounts.cacheReadInputTokens or 0
      total_tokens = total_tokens + input + output + cache_create + cache_read
    end
    total_cost = total_cost + (block.costUSD or 0)
  end

  if active_count > 0 then
    vim.health.info(string.format("Found %d active Claude Code session(s)", active_count))
  else
    vim.health.info(string.format("Found %d usage block(s) (no active sessions)", total_blocks))
  end

  if total_blocks > 0 then
    vim.health.info(string.format("Total usage: %d tokens, $%.4f USD", total_tokens, total_cost))
  end

  -- Test stats computation
  local stats_ok, stats = pcall(utils.compute_stats, blocks_data)
  if stats_ok and stats then
    vim.health.ok("Usage statistics computation working")
    vim.health.info(
      string.format("Current session: %d/%d tokens (%.1f%%)", stats.tokens, stats.max_tokens, stats.usage_ratio * 100)
    )
  else
    vim.health.warn("Statistics computation failed: " .. tostring(stats), "Component may not display correctly")
  end
end

--- Check if ccusage is configured in lualine sections
---@return nil
local function check_lualine_ccusage_configuration()
  local has_lualine, lualine = pcall(require, "lualine")

  if not has_lualine or not lualine.get_config then
    return false
  end

  local config = lualine.get_config()
  if not config or not config.sections then
    return false
  end

  -- Check all lualine sections for ccusage component
  local sections_to_check = { "lualine_a", "lualine_b", "lualine_c", "lualine_x", "lualine_y", "lualine_z" }
  local found_sections = {}

  for _, section_name in ipairs(sections_to_check) do
    local section = config.sections[section_name]
    if section and type(section) == "table" then
      for _, component in ipairs(section) do
        if component == "ccusage" or (type(component) == "table" and component[1] == "ccusage") then
          table.insert(found_sections, section_name)
          break
        end
      end
    end
  end

  return found_sections
end

--- Check lualine integration
---@return nil
local function check_lualine_integration()
  local has_lualine, lualine = pcall(require, "lualine")

  if not has_lualine then
    vim.health.warn(
      "lualine.nvim not found",
      "ccusage.nvim requires lualine for statusline integration",
      "Install lualine.nvim: use your preferred plugin manager"
    )
    return
  end

  vim.health.ok("lualine.nvim is available")

  -- Check if lualine version supports required features
  if lualine.get_config then
    vim.health.ok("lualine version supports configuration access")

    -- Check if ccusage is configured in lualine
    local configured_sections = check_lualine_ccusage_configuration()
    if configured_sections and #configured_sections > 0 then
      vim.health.ok("ccusage component found in lualine sections: " .. table.concat(configured_sections, ", "))
    else
      vim.health.warn(
        "ccusage component not found in lualine configuration",
        "Add 'ccusage' to your lualine sections to enable the component",
        "Example: sections = { lualine_x = { 'ccusage' } }"
      )
    end
  else
    vim.health.info("lualine version information not available")
  end

  -- Test component loading
  local component_ok, component_err = pcall(require, "lualine.components.ccusage")
  if component_ok then
    vim.health.ok("ccusage lualine component loads successfully")
  else
    vim.health.error(
      "ccusage lualine component failed to load: " .. tostring(component_err),
      "Component file may be missing or have syntax errors",
      "Check lua/lualine/components/ccusage.lua"
    )
    return
  end

  -- Provide setup guidance if not configured
  local configured_sections = check_lualine_ccusage_configuration()
  if not configured_sections or #configured_sections == 0 then
    vim.health.info("Add 'ccusage' to your lualine sections to enable the component")
    vim.health.info("Example: sections = { lualine_x = { 'ccusage' } }")
  end
end

--- Check additional system requirements
---@return nil
local function check_system_requirements()
  -- Check file system access for potential caching
  local temp_ok, temp_err = pcall(function()
    local temp_path = vim.fn.tempname()
    local file = io.open(temp_path, "w")
    if file then
      file:write("test")
      file:close()
      os.remove(temp_path)
      return true
    end
    return false
  end)

  if temp_ok then
    vim.health.ok("File system access available for caching")
  else
    vim.health.warn("File system access limited: " .. tostring(temp_err), "Component caching may not work optimally")
  end
end

--- Main health check function
--- Called by :checkhealth ccusage
---@return nil
function M.check()
  vim.health.start("ccusage.nvim")

  check_neovim_version()
  validate_configuration()
  check_ccusage_cli()
  check_data_access()
  check_lualine_integration()
  check_system_requirements()
end

return M
