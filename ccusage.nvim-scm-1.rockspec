---@diagnostic disable: lowercase-global

local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
version = _MODREV .. _SPECREV

local user = "S1M0N38"
package = "ccusage.nvim"

description = {
	summary = "Track Claude Code usage in Neovim",
	detailed = [[
ccusage.nvim is a Neovim plugin that integrates the ccusage CLI tool into your
statusline, providing real-time Claude Code usage monitoring directly in your editor.
  ]],
	labels = { "neovim", "statusline", "lualine", "claude", "usage-monitoring" },
	homepage = "https://github.com/" .. user .. "/" .. package,
	license = "MIT",
}

dependencies = {
	"lua >= 5.1",
}

test_dependencies = {
	"nlua",
}

source = {
	url = "git://github.com/" .. user .. "/" .. package,
}

build = {
	type = "builtin",
}
