---@class CCUsage.DataModule
local M = {}

---Get formatter context with unified error handling
---@param opts? {bypass_cache?: boolean, callback?: fun(data?: CCUsage.FormatterContext)}
---@return CCUsage.FormatterContext context with data/stats as nil if unavailable
M.get_formatter_context = function(opts)
  opts = opts or {}
  local cli = require("ccusage.cli")
  local utils = require("ccusage.utils")

  ---@type CCUsage.FormatterContext
  local context = { data = nil, stats = nil, loading = false }

  -- Helper to create context from blocks data
  local function create_context(blocks_data)
    if not blocks_data or not blocks_data.blocks or #blocks_data.blocks == 0 then
      return { data = nil, stats = nil, loading = false }
    end

    local stats = utils.compute_stats(blocks_data)
    return { data = blocks_data, stats = stats, loading = false }
  end

  -- Async mode with callback
  if opts.callback then
    cli.is_available({
      bypass_cache = opts.bypass_cache,
      callback = function(available)
        if not available then
          opts.callback(context)
          return
        end

        cli.ccusage_blocks({
          bypass_cache = opts.bypass_cache,
          callback = function(blocks_data)
            opts.callback(create_context(blocks_data))
          end,
        })
      end,
    })
    return context
  end

  -- Sync mode - simplified without loading states
  if not cli.is_available({ bypass_cache = opts.bypass_cache }) then
    return context
  end

  local blocks_data = cli.ccusage_blocks({ bypass_cache = opts.bypass_cache })
  return create_context(blocks_data)
end

return M
