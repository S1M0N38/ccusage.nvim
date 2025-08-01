-- ccusage.nvim plugin entry point
-- This file defines user commands for interacting with the plugin

---Get notification level based on usage statistics
---@param context CCUsage.FormatterContext Context with data and stats
---@return number vim.log.levels constant
local function get_log_level(context)
  if not context or not context.stats then
    return vim.log.levels.INFO
  end

  local stats = context.stats or {}

  if stats.usage_ratio > 1.0 then
    return vim.log.levels.ERROR
  elseif stats.usage_ratio >= 0.8 then
    return vim.log.levels.WARN
  else
    return vim.log.levels.INFO
  end
end

---Get notification title based on usage statistics
---@param context CCUsage.FormatterContext Context with data and stats
---@return string notification title
local function get_title(context)
  if not context or not context.stats then
    return "CCUsage"
  end

  local stats = context.stats or {}

  if stats.usage_ratio > 1.0 or stats.usage_ratio >= 0.8 then
    return "CCUsage Warning"
  else
    return "CCUsage Stats"
  end
end

---Display verbose Claude Code usage stats using vim.notify
---@return nil
local function status_cmd()
  local data = require("ccusage.data")
  local verbose_formatter = require("ccusage.formatters.verbose")

  -- Helper function to handle the formatted context
  local function handle_context(context)
    -- Handle errors with appropriate notifications
    if not context.data then
      vim.notify("ccusage CLI not found. Please install with: npm install -g ccusage", vim.log.levels.ERROR, {
        title = "CCUsage Error",
      })
      return
    end

    if not context.stats then
      vim.notify("Unable to compute usage statistics", vim.log.levels.WARN, {
        title = "CCUsage",
      })
      return
    end

    -- Format the data using the verbose formatter
    local formatted_message = verbose_formatter(context)
    if not formatted_message then
      vim.notify("Unable to format usage statistics", vim.log.levels.WARN, {
        title = "CCUsage",
      })
      return
    end

    -- Get appropriate log level and title
    local level = get_log_level(context)
    local title = get_title(context)

    -- Show notification
    vim.notify(formatted_message, level, {
      title = title,
      timeout = 5000, -- Show for 5 seconds
    })
  end

  -- Get formatter context with bypass cache and callback
  data.get_formatter_context({
    bypass_cache = true,
    callback = handle_context,
  })
end

vim.api.nvim_create_user_command("CCUsage", status_cmd, {
  desc = "Show Claude Code usage statistics with detailed formatting",
})

-- RESOURCES:
--  - :help lua-guide-commands-create
--  - https://github.com/nvim-neorocks/nvim-best-practices?tab=readme-ov-file#speaking_head-user-commands
