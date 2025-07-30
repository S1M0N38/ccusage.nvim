<div align="center">
  <h1>⌖&nbsp;&nbsp;ccusage.nvim&nbsp;&nbsp;⌖</h1>
  <p align="center">
    <a href="https://luarocks.org/modules/S1M0N38/ccusage.nvim">
      <img alt="LuaRocks release" src="https://img.shields.io/luarocks/v/S1M0N38/ccusage.nvim?style=for-the-badge&color=5d2fbf"/>
    </a>
    <a href="https://github.com/S1M0N38/ccusage.nvim/releases">
      <img alt="GitHub release" src="https://img.shields.io/github/v/release/S1M0N38/ccusage.nvim?style=for-the-badge&label=GitHub"/>
    </a>
    <a href="">
      <img alt="Reddit post" src="https://img.shields.io/badge/post-reddit?style=for-the-badge&label=Reddit&color=FF5700"/>
    </a>
  </p>
  <div><img src="" alt="Screenshot: ccusage.nvim example"></div>
  <p><em>Track Claude Code usage in Neovim</em></p>
</div>

---

## 💡 Motivation

As a [Claude Code](https://www.anthropic.com/claude-code) user with an Anthropic Pro subscription ($20/month), I frequently encounter usage limits during intensive development sessions (particularly when leveraging [SuperClaude](https://github.com/SuperClaude-Org/SuperClaude_Framework) enhancements). This requires careful management of API requests to maximize productivity within rate limits.

Anthropic currently implements usage limits based on a 5-hour rolling window [^1]. Once this window expires, usage limits reset automatically. The [ccusage](https://github.com/ryoppippi/ccusage) CLI tool provides an excellent solution for tracking Claude Code consumption patterns.

This plugin brings ccusage statistics directly into your Neovim workflow. It seamlessly integrates usage data into your statusline via lualine components and provides on-demand notifications through the `:CCUsage` command.


## ⚡️ Requirements

- Neovim ≥ 0.11
- [ccusage CLI tool](https://www.npmjs.com/package/ccusage) installed (`npm install -g ccusage`)
- [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) (optional)

## 📦 Installation

Install ccusage.nvim using your preferred plugin manager. Here's a complete configuration example for lazy.nvim:


```lua
-- Install and configure ccusage.nvim
{
  "S1M0N38/ccusage.nvim",
  version = "0.*",
  opts = {},
}
```

```lua
-- Enable ccusage lualine component
{
  "nvim-lualine/lualine.nvim",
  opts = {
    -- Add ccusage to your preferred lualine section
    sections = { lualine_x = { "ccusage" } },
    -- ... rest of your lualine configuration
  },
}
```


## 🚀 Usage

Get started by reading the comprehensive documentation with [`:help ccusage`](https://github.com/S1M0N38/ccusage.nvim/blob/main/doc/ccusage.txt), which covers all plugin features and configuration options.

> [!NOTE]
> **Mastering Vim/Neovim Documentation**: Most Vim/Neovim plugins include built-in `:help` documentation. Learning to navigate this system effectively is an invaluable skill for any Vim user. If you're new to this, start with `:help` and explore the first 20 lines to understand the navigation basics.


## 🙏 Acknowledgments

- [S1M0N38/base.nvim](https://github.com/S1M0N38/base.nvim) for the plugin template foundation
- [ryoppippi/ccusage](https://github.com/ryoppippi/ccusage) for the excellent ccusage CLI tool

[^1]: Anthropic hasn't published exact rate limit details. Based on observation, I estimate approximately 200 requests or 15M tokens per 5-hour session (roughly $8 worth of Sonnet 4 requests). Anthropic has indicated plans to implement weekly usage limits alongside session-based limits, and monthly caps may already be in effect.
