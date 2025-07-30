---@diagnostic disable: undefined-field
-- Unit tests for ccusage.data module
-- Tests the unified data access function

describe("ccusage.data module tests", function()
  local data, cli, utils

  -- Sample test data matching ccusage CLI JSON structure
  local sample_blocks_data = {
    blocks = {
      {
        id = "test-block-1",
        isActive = true,
        startTime = "2025-07-29T06:00:00.000Z",
        endTime = "2025-07-29T07:00:00.000Z",
        tokenCounts = {
          inputTokens = 1000,
          outputTokens = 2000,
          cacheCreationInputTokens = 500,
          cacheReadInputTokens = 300,
        },
        totalTokens = 3800,
        costUSD = 5.25,
        models = { "sonnet-4" },
      },
      {
        id = "test-block-2",
        isActive = false,
        startTime = "2025-07-29T05:00:00.000Z",
        endTime = "2025-07-29T06:00:00.000Z",
        tokenCounts = {
          inputTokens = 800,
          outputTokens = 1200,
        },
        totalTokens = 2000,
        costUSD = 3.15,
        models = { "sonnet-4" },
      },
    },
  }

  local sample_stats = {
    max_tokens = 10000,
    tokens = 3000,
    usage_ratio = 0.3,
    start_time = 1722240000,
    end_time = 1722243600,
    cost = 2.45,
    time_ratio = 0.5,
  }

  setup(function()
    -- Store original functions for restoration
    _G._test_originals = {
      io_popen = io.popen,
      os_time = os.time,
      os_date = os.date,
      os_difftime = os.difftime,
    }

    -- Mock system calls
    _G.io.popen = spy.new(function(_)
      local handle = {
        read = spy.new(function()
          return "1.0.0\n"
        end),
        close = spy.new(function()
          return true
        end),
      }
      return handle
    end)

    _G.os.time = spy.new(function()
      return 1722240000
    end)

    _G.os.date = spy.new(function()
      return "06"
    end)

    _G.os.difftime = spy.new(function()
      return 0
    end)
  end)

  teardown(function()
    -- Restore original functions
    if _G._test_originals then
      _G.io.popen = _G._test_originals.io_popen
      _G.os.time = _G._test_originals.os_time
      _G.os.date = _G._test_originals.os_date
      _G.os.difftime = _G._test_originals.os_difftime
      _G._test_originals = nil
    end

    -- Clear package.loaded
    package.loaded["ccusage.data"] = nil
    package.loaded["ccusage.cli"] = nil
    package.loaded["ccusage.utils"] = nil
  end)

  before_each(function()
    -- Clear spies before each test
    if io and io.popen and io.popen.clear then
      io.popen:clear()
    end
    if os and os.time and os.time.clear then
      os.time:clear()
    end

    -- Reload modules to ensure clean state
    package.loaded["ccusage.data"] = nil
    package.loaded["ccusage.cli"] = nil
    package.loaded["ccusage.utils"] = nil

    -- Load modules fresh
    data = require("ccusage.data")
    cli = require("ccusage.cli")
    utils = require("ccusage.utils")
  end)

  describe("get_formatter_context function", function()
    it("returns context with nil fields when CLI is not available", function()
      -- Mock CLI as unavailable
      local original_is_available = cli.is_available
      cli.is_available = function()
        return false
      end

      local context = data.get_formatter_context()

      assert.is_table(context)
      assert.is_nil(context.data)
      assert.is_nil(context.stats)

      -- Restore original function
      cli.is_available = original_is_available
    end)

    it("returns context with nil fields when no data available", function()
      -- Mock CLI as available but no data
      local original_is_available = cli.is_available
      local original_ccusage_blocks = cli.ccusage_blocks

      cli.is_available = function()
        return true
      end
      cli.ccusage_blocks = function()
        return nil
      end

      local context = data.get_formatter_context()

      assert.is_table(context)
      assert.is_nil(context.data)
      assert.is_nil(context.stats)

      -- Restore original functions
      cli.is_available = original_is_available
      cli.ccusage_blocks = original_ccusage_blocks
    end)

    it("returns context with nil fields when blocks are empty", function()
      -- Mock CLI as available but empty blocks
      local original_is_available = cli.is_available
      local original_ccusage_blocks = cli.ccusage_blocks

      cli.is_available = function()
        return true
      end
      cli.ccusage_blocks = function()
        return { blocks = {} }
      end

      local context = data.get_formatter_context()

      assert.is_table(context)
      assert.is_nil(context.data)
      assert.is_nil(context.stats)

      -- Restore original functions
      cli.is_available = original_is_available
      cli.ccusage_blocks = original_ccusage_blocks
    end)

    it("returns context with data but nil stats when stats computation fails", function()
      -- Mock CLI and data but stats computation fails
      local original_is_available = cli.is_available
      local original_ccusage_blocks = cli.ccusage_blocks
      local original_compute_stats = utils.compute_stats

      cli.is_available = function()
        return true
      end
      cli.ccusage_blocks = function()
        return sample_blocks_data
      end
      utils.compute_stats = function()
        return nil -- Stats computation failed
      end

      local context = data.get_formatter_context()

      assert.is_table(context)
      assert.is_table(context.data)
      assert.are.same(sample_blocks_data, context.data)
      assert.is_nil(context.stats)

      -- Restore original functions
      cli.is_available = original_is_available
      cli.ccusage_blocks = original_ccusage_blocks
      utils.compute_stats = original_compute_stats
    end)

    it("returns complete context when data and stats are available", function()
      -- Mock CLI, data, and stats as all available
      local original_is_available = cli.is_available
      local original_ccusage_blocks = cli.ccusage_blocks
      local original_compute_stats = utils.compute_stats

      cli.is_available = function()
        return true
      end
      cli.ccusage_blocks = function()
        return sample_blocks_data
      end
      utils.compute_stats = function(blocks_data)
        assert.are.same(sample_blocks_data, blocks_data)
        return sample_stats
      end

      local context = data.get_formatter_context()

      assert.is_table(context)
      assert.is_table(context.data)
      assert.is_table(context.stats)
      assert.are.same(sample_blocks_data, context.data)
      assert.are.same(sample_stats, context.stats)

      -- Restore original functions
      cli.is_available = original_is_available
      cli.ccusage_blocks = original_ccusage_blocks
      utils.compute_stats = original_compute_stats
    end)

    it("always returns a table with data and stats fields", function()
      -- Test various scenarios to ensure consistent return type
      local scenarios = {
        {
          name = "CLI unavailable",
          is_available = false,
          blocks_data = nil,
          expected_data = nil,
          expected_stats = nil,
        },
        {
          name = "No data",
          is_available = true,
          blocks_data = nil,
          expected_data = nil,
          expected_stats = nil,
        },
        {
          name = "Empty blocks",
          is_available = true,
          blocks_data = { blocks = {} },
          expected_data = nil,
          expected_stats = nil,
        },
        {
          name = "Valid data",
          is_available = true,
          blocks_data = sample_blocks_data,
          expected_data = sample_blocks_data,
          expected_stats = sample_stats,
        },
      }

      for _, scenario in ipairs(scenarios) do
        local original_is_available = cli.is_available
        local original_ccusage_blocks = cli.ccusage_blocks
        local original_compute_stats = utils.compute_stats

        cli.is_available = function()
          return scenario.is_available
        end
        cli.ccusage_blocks = function()
          return scenario.blocks_data
        end
        utils.compute_stats = function()
          return scenario.expected_stats
        end

        local context = data.get_formatter_context()

        assert.is_table(context, "Context should be table for scenario: " .. scenario.name)

        if scenario.expected_data then
          assert.are.same(scenario.expected_data, context.data, "Data mismatch for scenario: " .. scenario.name)
        else
          assert.is_nil(context.data, "Data should be nil for scenario: " .. scenario.name)
        end

        if scenario.expected_stats then
          assert.are.same(scenario.expected_stats, context.stats, "Stats mismatch for scenario: " .. scenario.name)
        else
          assert.is_nil(context.stats, "Stats should be nil for scenario: " .. scenario.name)
        end

        -- Restore functions for next iteration
        cli.is_available = original_is_available
        cli.ccusage_blocks = original_ccusage_blocks
        utils.compute_stats = original_compute_stats
      end
    end)
  end)

  describe("module structure", function()
    it("has get_formatter_context function", function()
      assert.is_function(data.get_formatter_context)
    end)

    it("get_formatter_context can be called without error", function()
      assert.has_no.errors(function()
        data.get_formatter_context()
      end)
    end)

    it("get_formatter_context always returns a value", function()
      local result = data.get_formatter_context()
      assert.is_not_nil(result)
    end)
  end)
end)
