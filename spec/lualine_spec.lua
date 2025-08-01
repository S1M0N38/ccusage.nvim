---@diagnostic disable: inject-field
-- Integration tests for ccusage.nvim with lualine
-- Tests actual plugin integration with real lualine.nvim setup

-- Setup test environment with plugins
setup(function()
  vim.env.LAZY_STDPATH = ".repro"
  load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

  local plugins = {
    {
      "nvim-lualine/lualine.nvim",
      opts = { sections = { lualine_x = { "ccusage" } } },
    },
  }

  require("lazy.minit").repro({ spec = plugins })
end)

describe("ccusage lualine integration tests", function()
  local ccusage_component

  before_each(function()
    -- Setup ccusage plugin with default configuration
    require("ccusage").setup({})

    -- Get the lualine component
    ccusage_component = require("lualine.components.ccusage")
  end)

  after_each(function()
    -- Clear package.loaded for clean state between tests
    package.loaded["ccusage"] = nil
    package.loaded["ccusage.config"] = nil
    package.loaded["ccusage.cli"] = nil
    package.loaded["lualine.components.ccusage"] = nil
  end)

  describe("lualine component loading", function()
    it("can be required without error", function()
      local ok, component = pcall(require, "lualine.components.ccusage")

      assert.is_true(ok)
      assert.is_function(component)
    end)

    it("is a function that returns a string", function()
      assert.is_function(ccusage_component)

      local result = ccusage_component()

      assert.is_string(result)
    end)
  end)

  describe("component behavior when CLI is unavailable", function()
    it("returns 'loading...' message when CLI is being checked or data is being fetched", function()
      -- Mock data module to return loading state
      local data = require("ccusage.data")
      local original_get_formatter_context = data.get_formatter_context
      data.get_formatter_context = function()
        return { data = nil, stats = nil, loading = true } -- Currently loading
      end

      local result = ccusage_component()

      assert.are.equal("ccusage: loading...", result)

      -- Restore original function
      data.get_formatter_context = original_get_formatter_context
    end)

    it("returns 'not found' message when ccusage CLI is not available", function()
      -- Mock data module to return no data
      local data = require("ccusage.data")
      local original_get_formatter_context = data.get_formatter_context
      data.get_formatter_context = function()
        return { data = nil, stats = nil, loading = false } -- CLI unavailable
      end

      local result = ccusage_component()

      assert.are.equal("ccusage: not found", result)

      -- Restore original function
      data.get_formatter_context = original_get_formatter_context
    end)
  end)

  describe("component behavior when CLI is available", function()
    it("returns 'no stats' message when data exists but stats cannot be computed", function()
      -- Mock data module to return data but no stats
      local data = require("ccusage.data")
      local original_get_formatter_context = data.get_formatter_context
      data.get_formatter_context = function()
        return { data = { blocks = {} }, stats = nil, loading = false } -- Data but no stats
      end

      local result = ccusage_component()

      assert.are.equal("ccusage: no stats", result)

      -- Restore original function
      data.get_formatter_context = original_get_formatter_context
    end)

    it("uses formatter function when stats are available", function()
      local sample_data = {
        blocks = {
          {
            id = "test-block",
            isActive = true,
            startTime = "2025-07-29T06:00:00.000Z",
            endTime = "2025-07-29T07:00:00.000Z",
            tokenCounts = {
              inputTokens = 1000,
              outputTokens = 2000,
            },
            totalTokens = 3000,
            costUSD = 2.50,
            models = { "sonnet-4" },
          },
        },
      }

      local sample_stats = {
        max_tokens = 10000,
        tokens = 3000,
        usage_ratio = 0.3,
        time_ratio = 0.5,
      }

      -- Mock data module to return valid data and stats
      local data = require("ccusage.data")
      local original_get_formatter_context = data.get_formatter_context
      data.get_formatter_context = function()
        return { data = sample_data, stats = sample_stats, loading = false }
      end

      local result = ccusage_component()

      -- Should return formatted string (not error messages)
      assert.is_string(result)
      assert.is_not.equal("ccusage: not found", result)
      assert.is_not.equal("ccusage: no stats", result)
      assert.is_not.equal("ccusage: no formatter", result)

      -- Should contain expected elements from default formatter
      assert.is_true(string.match(result, "time") ~= nil)
      assert.is_true(string.match(result, "tok") ~= nil)

      -- Restore original function
      data.get_formatter_context = original_get_formatter_context
    end)

    it("handles custom formatter function", function()
      -- Setup with custom formatter
      require("ccusage").setup({
        formatter = function(context)
          if not context or not context.stats then
            return nil
          end
          return "custom: " .. tostring(context.stats.usage_ratio * 100) .. "%"
        end,
      })

      local sample_data = {
        blocks = {
          {
            id = "test-block",
            isActive = true,
            startTime = "2025-07-29T06:00:00.000Z",
            totalTokens = 5000,
            costUSD = 1.00,
            models = { "sonnet-4" },
          },
        },
      }

      local sample_stats = {
        max_tokens = 10000,
        tokens = 5000,
        usage_ratio = 0.5,
        time_ratio = 0.3,
      }

      -- Mock data module
      local data = require("ccusage.data")
      local original_get_formatter_context = data.get_formatter_context
      data.get_formatter_context = function()
        return { data = sample_data, stats = sample_stats, loading = false }
      end

      -- Reload component to pick up new config
      package.loaded["lualine.components.ccusage"] = nil
      ccusage_component = require("lualine.components.ccusage")

      local result = ccusage_component()

      assert.is_string(result)
      assert.is_true(string.match(result, "custom:") ~= nil)

      -- Restore original function
      data.get_formatter_context = original_get_formatter_context
    end)

    it("hides component when formatter returns nil", function()
      -- Setup with formatter that returns nil
      require("ccusage").setup({
        formatter = function(_)
          return nil -- Always hide component
        end,
      })

      local sample_data = {
        blocks = {
          {
            id = "test-block",
            isActive = true,
            totalTokens = 1000,
            costUSD = 1.00,
            models = { "sonnet-4" },
          },
        },
      }

      local sample_stats = {
        max_tokens = 10000,
        tokens = 1000,
        usage_ratio = 0.1,
        time_ratio = 0.2,
      }

      -- Mock data module
      local data = require("ccusage.data")
      local original_get_formatter_context = data.get_formatter_context
      data.get_formatter_context = function()
        return { data = sample_data, stats = sample_stats, loading = false }
      end

      -- Reload component to pick up new config
      package.loaded["lualine.components.ccusage"] = nil
      ccusage_component = require("lualine.components.ccusage")

      local result = ccusage_component()

      assert.are.equal("", result) -- Component should be hidden (empty string)

      -- Restore original function
      data.get_formatter_context = original_get_formatter_context
    end)
  end)

  describe("lualine integration", function()
    it("can be used in lualine configuration", function()
      -- Test that lualine can load and use the component without errors
      local ok, lualine = pcall(require, "lualine")

      assert.is_true(ok)
      assert.is_table(lualine)

      -- Test basic lualine setup with ccusage component
      local setup_ok = pcall(function()
        lualine.setup({
          sections = {
            lualine_x = { "ccusage" },
          },
        })
      end)

      assert.is_true(setup_ok)
    end)

    it("integrates with lualine component system", function()
      -- Verify that our component can be called in lualine context
      local lualine = require("lualine")

      -- Setup lualine with our component
      lualine.setup({
        sections = {
          lualine_x = { "ccusage" },
        },
      })

      -- Component should be callable without errors
      local ok, result = pcall(ccusage_component)

      assert.is_true(ok)
      assert.is_string(result)
    end)
  end)

  describe("configuration integration", function()
    it("respects ccusage_cmd configuration", function()
      -- Setup with custom command
      require("ccusage").setup({
        ccusage_cmd = "custom-ccusage-command",
      })

      local config = require("ccusage.config")

      assert.are.equal("custom-ccusage-command", config.options.ccusage_cmd)
    end)

    it("uses custom formatter configuration", function()
      local custom_formatter = function(_)
        return "test-format"
      end

      require("ccusage").setup({
        formatter = custom_formatter,
      })

      local config = require("ccusage.config")

      assert.are.equal(custom_formatter, config.options.formatter)
    end)
  end)

  describe("error handling", function()
    it("handles missing formatter gracefully", function()
      -- Setup with invalid formatter (not a function)
      require("ccusage").setup({
        formatter = "not-a-function", ---@diagnostic disable-line: assign-type-mismatch
      })

      local sample_data = {
        blocks = {
          {
            id = "test-block",
            isActive = true,
            totalTokens = 1000,
            costUSD = 1.00,
            models = { "sonnet-4" },
          },
        },
      }

      local sample_stats = {
        max_tokens = 10000,
        tokens = 1000,
        usage_ratio = 0.1,
        time_ratio = 0.2,
      }

      -- Mock data module
      local data = require("ccusage.data")
      local original_get_formatter_context = data.get_formatter_context
      data.get_formatter_context = function()
        return { data = sample_data, stats = sample_stats, loading = false }
      end

      -- Reload component to pick up new config
      package.loaded["lualine.components.ccusage"] = nil
      ccusage_component = require("lualine.components.ccusage")

      local result = ccusage_component()

      assert.are.equal("ccusage: no formatter", result)

      -- Restore original functions
      data.get_formatter_context = original_get_formatter_context
    end)

    it("handles component loading errors gracefully", function()
      -- Test that the component doesn't crash on unexpected errors
      local ok, result = pcall(ccusage_component)

      assert.is_true(ok)
      assert.is_string(result)
    end)
  end)
end)
