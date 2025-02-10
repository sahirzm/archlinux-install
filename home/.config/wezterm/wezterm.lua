local wezterm = require("wezterm")

local config = {}
config.color_scheme = "Tokyo Night Moon"

config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 3000 }
config.keys = {
	{
		key = "|",
		mods = "LEADER|SHIFT",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "-",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
}

config.window_decorations = "RESIZE"
config.use_fancy_tab_bar = false

return config
