# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ccusage.nvim is a minimal Neovim plugin that integrates the ccusage CLI tool into lualine statuslines. It provides real-time Claude Code usage monitoring, displaying token counts and costs with customizable formatting.

## Commands & Development Workflow

### Testing
- **Run all tests**: `busted .`
- **Single test file**: `busted spec/ccusage_spec.lua`
- **Test with specific pattern**: `busted --pattern="specific_test_name"`

### Development Testing
- **Health check**: `:checkhealth ccusage` (in Neovim)
- **Minimal reproduction**: `nvim -u repro/repro.lua`
- **Test command**: `:CCUsage` (displays usage stats notification)

### CLI Dependencies
- **ccusage CLI**: Required external dependency (`npm install -g ccusage`)
- **Commands used**: `ccusage blocks --json --offline`, `ccusage --version`

## Architecture

### Core Module Structure
- **`lua/ccusage/init.lua`**: Main entry point with `setup()` function
- **`lua/ccusage/config.lua`**: Configuration management with defaults and user options merging
- **`lua/ccusage/cli.lua`**: CLI interface with caching (5-second cache), async job management via `vim.fn.jobstart`
- **`lua/ccusage/data.lua`**: Data processing layer that coordinates CLI and stats computation
- **`lua/ccusage/utils.lua`**: Utility functions for time parsing, command checking, and stats calculation

### Plugin Integration Points
- **`plugin/ccusage.lua`**: Defines `:CCUsage` command with notification system
- **`lua/lualine/components/ccusage.lua`**: Lualine component integration
- **`lua/ccusage/health.lua`**: Health check implementation for `:checkhealth ccusage`

### Data Flow Architecture
1. **CLI Layer** (`cli.lua`): Executes `ccusage` command asynchronously, handles JSON parsing and caching
2. **Data Layer** (`data.lua`): Coordinates between CLI data and computed statistics
3. **Utils Layer** (`utils.lua`): Computes stats from raw blocks data (max_tokens, usage_ratio, time_ratio, cost)
4. **Formatter Layer** (`formatters/*.lua`): Transforms data into display strings with color coding
5. **Display Layer** (lualine component/command): Presents formatted data to user

### Key Data Structures
- **CCUsage.Block**: Raw block data from ccusage CLI with tokenCounts, costUSD, timestamps
- **CCUsage.Stats**: Computed statistics (usage_ratio, time_ratio, max_tokens, cost)
- **CCUsage.FormatterContext**: Combined data/stats object passed to formatter functions

### Formatter System
- **Default formatter** (`formatters/default.lua`): Shows "time 75% | tok 45%" with color coding
- **Verbose formatter** (`formatters/verbose.lua`): Detailed stats for `:CCUsage` command
- **Custom formatters**: User-configurable via `formatter` option in setup

### Error Handling Strategy
- **Graceful degradation**: Missing CLI/data shows appropriate fallback messages
- **Unified error handling**: `data.get_formatter_context()` centralizes error states
- **User feedback**: Clear messages for missing dependencies or invalid data

## Context7 Documentation Resources

Available documentation for integration and development:
- **Neovim**: `/neovim/neovim` - Core Neovim APIs and patterns
- **Busted**: `lunarmodules_github_io-busted` - Testing framework documentation
- **lualine**: `/nvim-lualine/lualine.nvim` - Statusline component patterns
- **ccusage**: `/ryoppippi/ccusage` - CLI tool data structures and usage

## Testing Architecture

- **Busted framework**: Uses spies and mocks for external dependencies
- **Mock strategy**: Mocks `io.popen`, `os.time`, `os.date` for deterministic tests
- **Sample data**: Comprehensive test fixtures matching real ccusage CLI output
- **Module isolation**: Each test reloads modules for clean state
- **Coverage areas**: Config merging, CLI handling, stats computation, formatters, error conditions