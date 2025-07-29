-- repro/repro.lua serves as a reproducible environment for your plugin.
-- Whwn user want to open a new ISSUE, they are asked to reproduce their issue in a clean minial environment.
-- repro directory is a safe place to mess around with various config without affecting your main setup.
--
-- 1. Clone ccusage.nvim and cd into ccusage.nvim
-- 2. Run `nvim -u repro/repro.lua`
-- 3. Run :checkhealth ccusage
-- 4. Reproduce the issue
-- 5. Report the repro.lua and logs from .repro directory in the issue

vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

local plugins = {
  {
    dir = "/path/to/ccusage.nvim", -- Change to your plugin path
    opts = {},
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = { lualine_x = { "ccusage" } },
    },
  },
}

require("lazy.minit").repro({ spec = plugins })
