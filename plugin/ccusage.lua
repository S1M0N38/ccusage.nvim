-- ccusage.nvim plugin entry point
-- This file defines user commands for interacting with the plugin

local cli = require("ccusage.cli")

---Display current Claude Code usage status
---@return nil
local function status_cmd()
  local blocks_data = cli.ccusage_blocks()
  if blocks_data and blocks_data.blocks and #blocks_data.blocks > 0 then
    vim.print("Current Claude Code usage blocks:")
    vim.print(vim.inspect(blocks_data))
  else
    vim.print("No Claude Code usage data found")
  end
end

-- TODO: change the command behavior to notify with usage stats
vim.api.nvim_create_user_command("CCUsage", status_cmd, {
  desc = "Show Claude Code usage status",
})

-- RESOURCES:
--  - :help lua-guide-commands-create
--  - https://github.com/nvim-neorocks/nvim-best-practices?tab=readme-ov-file#speaking_head-user-commands
