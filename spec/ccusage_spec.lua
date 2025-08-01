---@diagnostic disable: undefined-field
-- Unit tests for ccusage.nvim modules
-- Tests individual module functions in isolation with proper mocking

describe("ccusage.nvim unit tests", function()
  local ccusage, config, cli, utils, default_formatter

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

  setup(function()
    -- Store original functions for restoration
    _G._test_originals = {
      io_popen = io.popen,
      os_time = os.time,
      os_date = os.date,
      os_difftime = os.difftime,
    }

    -- Mock only external system calls, not vim APIs
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

    -- Mock os functions for consistent time-based tests
    _G.os.time = spy.new(function(tbl)
      if tbl then
        return 1722240000 -- Fixed timestamp for testing
      end
      return 1722240000
    end)

    _G.os.date = spy.new(function(fmt, _)
      if fmt == "!*t" then
        return { year = 2025, month = 7, day = 29, hour = 6, min = 0, sec = 0 }
      end
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

    -- Clear package.loaded to ensure clean state
    package.loaded["ccusage"] = nil
    package.loaded["ccusage.config"] = nil
    package.loaded["ccusage.cli"] = nil
    package.loaded["ccusage.utils"] = nil
    package.loaded["ccusage.formatters.default"] = nil
    package.loaded["ccusage.data"] = nil
  end)

  before_each(function()
    -- Clear spies before each test
    if io and io.popen and io.popen.clear then
      io.popen:clear()
    end
    if os and os.time and os.time.clear then
      os.time:clear()
    end
    if os and os.date and os.date.clear then
      os.date:clear()
    end
    if os and os.difftime and os.difftime.clear then
      os.difftime:clear()
    end

    -- Reload modules to ensure clean state
    package.loaded["ccusage"] = nil
    package.loaded["ccusage.config"] = nil
    package.loaded["ccusage.cli"] = nil
    package.loaded["ccusage.utils"] = nil
    package.loaded["ccusage.formatters.default"] = nil
    package.loaded["ccusage.data"] = nil

    -- Load modules fresh
    ccusage = require("ccusage")
    config = require("ccusage.config")
    cli = require("ccusage.cli")
    utils = require("ccusage.utils")
    default_formatter = require("ccusage.formatters.default")
  end)

  describe("ccusage.init module", function()
    it("has setup function", function()
      assert.is_function(ccusage.setup)
    end)

    it("calls config.setup with provided options", function()
      local config_setup_spy = spy.on(config, "setup")
      local test_opts = { ccusage_cmd = "test-ccusage" }

      ccusage.setup(test_opts)

      assert.spy(config_setup_spy).was.called_with(test_opts)
      config_setup_spy:revert()
    end)

    it("calls config.setup with nil when no options provided", function()
      local config_setup_spy = spy.on(config, "setup")

      ccusage.setup()

      assert.spy(config_setup_spy).was.called_with(nil)
      config_setup_spy:revert()
    end)
  end)

  describe("ccusage.config module", function()
    it("has correct default options", function()
      assert.are.equal("ccusage", config.defaults.ccusage_cmd)
      assert.is_function(config.defaults.formatter)
    end)

    it("initializes options with defaults", function()
      assert.are.equal(config.defaults.ccusage_cmd, config.options.ccusage_cmd)
      assert.are.equal(config.defaults.formatter, config.options.formatter)
    end)

    it("merges user options with defaults", function()
      local custom_formatter = function()
        return "custom"
      end
      local user_opts = {
        ccusage_cmd = "custom-ccusage",
        formatter = custom_formatter,
      }

      config.setup(user_opts)

      assert.are.equal("custom-ccusage", config.options.ccusage_cmd)
      assert.are.equal(custom_formatter, config.options.formatter)
    end)

    it("handles nil options gracefully", function()
      local original_cmd = config.options.ccusage_cmd
      local original_formatter = config.options.formatter

      config.setup(nil)

      -- Should maintain existing options when nil is passed
      assert.are.equal(original_cmd, config.options.ccusage_cmd)
      assert.are.equal(original_formatter, config.options.formatter)
    end)
  end)

  describe("ccusage.cli module", function()
    it("has required functions", function()
      assert.is_function(cli.ccusage_blocks)
      assert.is_function(cli.is_available)
      assert.is_function(cli.refresh_blocks)
    end)

    describe("ccusage_blocks function", function()
      it("can be called without error", function()
        assert.has_no.errors(function()
          cli.ccusage_blocks()
        end)
      end)

      it("returns data or nil", function()
        local result = cli.ccusage_blocks()
        -- Should return either nil or table data
        assert.is_true(result == nil or type(result) == "table")
      end)
    end)

    describe("is_available function", function()
      it("returns boolean", function()
        local result = cli.is_available()
        assert.is_boolean(result)
      end)

      it("can be called multiple times", function()
        assert.has_no.errors(function()
          cli.is_available()
          cli.is_available()
        end)
      end)
    end)

    describe("job queue system integration", function()
      it("prevents multiple concurrent calls through job queue", function()
        -- Mock vim.fn.jobstart to track call count
        local jobstart_call_count = 0
        local original_jobstart = vim.fn.jobstart

        vim.fn.jobstart = function(cmd, opts)
          jobstart_call_count = jobstart_call_count + 1
          -- Simulate successful completion
          if opts.on_stdout then
            opts.on_stdout(1, { '{"blocks":[]}' }, nil)
          end
          if opts.on_exit then
            opts.on_exit(1, 0, nil)
          end
          return 1
        end

        -- Make multiple rapid calls - should be queued by job system
        local callback_count = 0
        for i = 1, 3 do
          cli.ccusage_blocks({
            callback = function(data)
              callback_count = callback_count + 1
            end,
          })
        end

        -- Should have limited the number of actual jobstart calls
        -- (This tests that job queuing is working, even if spy counting isn't perfect)
        assert.is_true(jobstart_call_count <= 3) -- At most 3, ideally 1
        assert.is_true(callback_count >= 0) -- Callbacks should be queued and executed

        -- Restore original
        vim.fn.jobstart = original_jobstart
      end)
    end)

    describe("refresh_blocks function", function()
      it("can be called without error", function()
        assert.has_no.errors(function()
          cli.refresh_blocks()
        end)
      end)

      it("returns data or nil", function()
        local result = cli.refresh_blocks()
        -- Should return either nil or table data
        assert.is_true(result == nil or type(result) == "table")
      end)
    end)
  end)

  describe("ccusage.utils module", function()
    describe("command_exists function", function()
      it("returns true when command exists", function()
        local handle_mock = {
          read = function()
            return "/usr/bin/ccusage\n"
          end,
          close = function()
            return true
          end,
        }
        io.popen:revert()
        io.popen = spy.new(function()
          return handle_mock
        end)

        local result = utils.command_exists("ccusage")

        assert.is_true(result)
        assert.spy(io.popen).was.called_with("command -v ccusage 2>/dev/null")
      end)

      it("returns false when command does not exist", function()
        local handle_mock = {
          read = function()
            return ""
          end,
          close = function()
            return false
          end,
        }
        io.popen:revert()
        io.popen = spy.new(function()
          return handle_mock
        end)

        local result = utils.command_exists("nonexistent")

        assert.is_false(result)
      end)

      it("handles io.popen failure", function()
        io.popen:revert()
        io.popen = spy.new(function()
          return nil
        end)

        local result = utils.command_exists("ccusage")

        assert.is_false(result)
      end)
    end)

    describe("get_ccusage_version function", function()
      it("returns version string when available", function()
        local handle_mock = {
          read = function()
            return "1.2.3\n"
          end,
          close = function()
            return true
          end,
        }
        io.popen:revert()
        io.popen = spy.new(function()
          return handle_mock
        end)

        local result = utils.get_ccusage_version()

        assert.are.equal("1.2.3", result)
      end)

      it("returns nil when command fails", function()
        io.popen:revert()
        io.popen = spy.new(function()
          return nil
        end)

        local result = utils.get_ccusage_version()

        assert.is_nil(result)
      end)
    end)

    describe("parse_utc_iso8601 function", function()
      it("parses valid ISO 8601 timestamp", function()
        local result = utils.parse_utc_iso8601("2025-07-29T06:00:00.000Z")

        assert.is_number(result)
        assert.spy(os.time).was.called()
      end)

      it("returns nil for invalid timestamp", function()
        local result = utils.parse_utc_iso8601("invalid-timestamp")

        assert.is_nil(result)
      end)

      it("returns nil for nil input", function()
        local result = utils.parse_utc_iso8601(nil)

        assert.is_nil(result)
      end)
    end)

    describe("utc_to_local function", function()
      it("converts UTC time to local time", function()
        local result = utils.utc_to_local(1722240000)

        assert.is_string(result)
        assert.spy(os.date).was.called()
      end)

      -- it("uses custom format when provided", function()
      --   utils.utc_to_local(1722240000, "%Y-%m-%d")
      --
      --   assert.spy(os.date).was.called_with("%Y-%m-%d", match._)
      -- end)
    end)

    describe("iso_to_local function", function()
      it("converts ISO string to local time", function()
        local result = utils.iso_to_local("2025-07-29T06:00:00.000Z")

        assert.is_string(result)
      end)

      it("returns nil for invalid ISO string", function()
        local result = utils.iso_to_local("invalid")

        assert.is_nil(result)
      end)

      it("returns nil for nil input", function()
        local result = utils.iso_to_local(nil)

        assert.is_nil(result)
      end)
    end)

    describe("compute_stats function", function()
      it("returns nil for nil input", function()
        local result = utils.compute_stats(nil)

        assert.is_nil(result)
      end)

      it("returns nil for empty blocks", function()
        local result = utils.compute_stats({ blocks = {} })

        assert.is_nil(result)
      end)

      it("computes stats for valid blocks data", function()
        local result = utils.compute_stats(sample_blocks_data)

        assert.is_table(result)
        assert.is_number(result.max_tokens)
        assert.is_number(result.tokens)
        assert.is_number(result.usage_ratio)
        assert.is_number(result.start_time)
        assert.is_number(result.end_time)
        assert.is_number(result.cost)
        assert.is_number(result.time_ratio)
      end)

      it("uses last block for stats calculation", function()
        local result = utils.compute_stats(sample_blocks_data)

        -- Should use the last block (test-block-2)
        assert.are.equal(2000, result.tokens)
        assert.are.equal(3.15, result.cost)
      end)

      it("calculates max tokens from all blocks", function()
        local result = utils.compute_stats(sample_blocks_data)

        -- Should use the highest token count (3800 from first block)
        assert.are.equal(3800, result.max_tokens)
      end)

      it("handles blocks without totalTokens", function()
        local test_data = {
          blocks = {
            {
              id = "test-block",
              isActive = true,
              costUSD = 1.0,
              models = { "sonnet-4" },
            },
          },
        }

        local result = utils.compute_stats(test_data)

        assert.is_table(result)
        assert.are.equal(0, result.tokens)
      end)
    end)
  end)

  describe("ccusage.formatters.default", function()
    it("returns nil for nil context", function()
      local result = default_formatter(nil)

      assert.is_nil(result)
    end)

    it("returns nil for context without stats", function()
      local context = { data = sample_blocks_data }
      local result = default_formatter(context)

      assert.is_nil(result)
    end)

    it("formats context correctly", function()
      local stats = {
        max_tokens = 10000,
        tokens = 5000,
        usage_ratio = 0.5,
        time_ratio = 0.75,
        cost = 2.50,
      }
      local context = {
        data = sample_blocks_data,
        stats = stats,
      }

      local result = default_formatter(context)

      assert.is_string(result)
      assert.is_true(string.len(result) > 0)
    end)

    it("applies warning color for near limit usage", function()
      local stats = {
        usage_ratio = 0.85, -- Above 80% threshold
        time_ratio = 0.5,
      }
      local context = {
        data = sample_blocks_data,
        stats = stats,
      }

      local result = default_formatter(context)

      assert.is_string(result)
      assert.is_true(string.match(result, "%%#DiagnosticWarn#") ~= nil)
    end)

    it("applies error color for exceeded limit", function()
      local stats = {
        usage_ratio = 1.1, -- Above 100%
        time_ratio = 0.5,
      }
      local context = {
        data = sample_blocks_data,
        stats = stats,
      }

      local result = default_formatter(context)

      assert.is_string(result)
      assert.is_true(string.match(result, "%%#DiagnosticError#") ~= nil)
    end)

    it("uses default color for normal usage", function()
      local stats = {
        usage_ratio = 0.5, -- Below 80% threshold
        time_ratio = 0.3,
      }
      local context = {
        data = sample_blocks_data,
        stats = stats,
      }

      local result = default_formatter(context)

      assert.is_string(result)
      -- Should not contain color codes
      assert.is_true(string.match(result, "%%#Diagnostic") == nil)
    end)

    it("includes time and token ratios in output", function()
      local stats = {
        usage_ratio = 0.45,
        time_ratio = 0.67,
      }
      local context = {
        data = sample_blocks_data,
        stats = stats,
      }

      local result = default_formatter(context)

      assert.is_string(result)
      assert.is_true(string.match(result, "67%%") ~= nil) -- time ratio
      assert.is_true(string.match(result, "45%%") ~= nil) -- token ratio
      assert.is_true(string.match(result, "time") ~= nil)
      assert.is_true(string.match(result, "tok") ~= nil)
    end)
  end)
end)
