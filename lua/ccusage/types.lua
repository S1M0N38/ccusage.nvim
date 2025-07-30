---@meta
--- This is a simple "definition file" (https://luals.github.io/wiki/definition-files/),
--- the @meta tag at the top is its hallmark.

-- lua/ccusage/init.lua --------------------------------------------------------

---@class CCUsage.Plugin
---@field setup function setup the plugin
---@field show_usage_stats function display verbose Claude Code usage stats using vim.notify

-- lua/ccusage/config.lua ------------------------------------------------------

---@class CCUsage.Config
---@field defaults CCUsage.Options default options
---@field options CCUsage.Options user options
---@field setup function setup the plugin

---@class CCUsage.UserOptions
---@field ccusage_cmd? string ccusage command to run
---@field formatter? fun(context: CCUsage.FormatterContext): string? function to format context data for display

---@class CCUsage.DefaultOptions
---@field ccusage_cmd string ccusage command to run
---@field formatter fun(context: CCUsage.FormatterContext): string|nil function to format context data for display

---@class CCUsage.Options
---@field ccusage_cmd string ccusage command to run
---@field formatter fun(context: CCUsage.FormatterContext): string|nil function to format context data for display

-- lua/ccusage/cli.lua ---------------------------------------------------------

---@class CCUsage.CLI
---@field ccusage_blocks fun(): CCUsage.Data|nil get ccusage blocks data
---@field is_available fun(): boolean check if ccusage CLI is available
---@field refresh_blocks fun(): CCUsage.Data|nil force refresh ccusage blocks data

---@class CCUsage.Block
---@field id string block identifier
---@field startTime string block start time
---@field endTime string block end time
---@field actualEndTime? string actual end time if completed
---@field isActive boolean whether the block is currently active
---@field isGap? boolean whether this is a gap block
---@field tokenCounts CCUsage.TokenCounts token usage counts
---@field totalTokens? number total token count
---@field costUSD number cost in USD
---@field models table list of models used
---@field projection? table projected values for incomplete blocks

---@class CCUsage.TokenCounts
---@field inputTokens number input token count
---@field outputTokens number output token count
---@field cacheCreationInputTokens? number cache creation input tokens
---@field cacheReadInputTokens? number cache read input tokens

---@class CCUsage.Data
---@field blocks CCUsage.Block[] array of CCUsage.Block

---@class CCUsage.Stats
---@field max_tokens number maximum tokens allowed for block
---@field tokens number current token count
---@field usage_ratio number usage ratio as float (0.0-1.0+)
---@field start_time number start time as unix epoch utc
---@field end_time number end time as unix epoch utc
---@field cost number cost in USD as float
---@field time_ratio number time progress ratio as float (0.0-1.0)

---@class CCUsage.FormatterContext
---@field data CCUsage.Data? -- Raw JSON data from ccusage command
---@field stats CCUsage.Stats? -- Pre-computed stats from data for convenience

-- lua/ccusage/utils.lua -------------------------------------------------------

---@class CCUsage.Utils
---@field command_exists fun(cmd: string): boolean? check if a command exists
---@field get_ccusage_version fun(): string|nil get ccusage version
---@field parse_utc_iso8601 fun(str: string): number? parse ISO 8601 UTC timestamp to unix timestamp
---@field utc_to_local fun(utc_time: number, format?: string): string convert UTC time to local time string
---@field iso_to_local fun(iso_str?: string, format?: string): string? convert ISO 8601 UTC timestamp to local time string
---@field compute_stats fun(blocks_data: CCUsage.Data): CCUsage.Stats|nil compute stats from blocks data

-- lua/ccusage/health.lua -------------------------------------------------------

---@class CCUsage.Health
---@field check fun(): nil perform health check for the plugin
