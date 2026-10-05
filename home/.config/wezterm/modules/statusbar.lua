-- Catppuccin/tmux appearance using tabline.wez's built-in components.
local wezterm = require("wezterm")
local tabline = require("modules.plugins").tabline
local M = {}

function M.apply(config)
	local rounded = {
		left = wezterm.nerdfonts.ple_right_half_circle_thick,
		right = wezterm.nerdfonts.ple_left_half_circle_thick,
	}
	local title = { "tab", fmt = function(_, tab)
		return tab.tab_title ~= "" and tab.tab_title or tab.active_pane.title
	end }
	tabline.setup({
		options = {
			theme = "Catppuccin Mocha",
			section_separators = rounded,
			tab_separators = rounded,
			theme_overrides = {
				normal_mode = {
					a = { fg = "#181825", bg = "#a6e3a1" },
					b = { fg = "#a6e3a1", bg = "#313244" },
				},
			},
		},
		sections = {
			tabline_a = { { "mode", fmt = function(mode, window)
				return window:leader_is_active() and "LEADER" or mode
			end } },
			tabline_b = { "workspace" },
			tabline_c = {},
			tab_active = { { "index", zero_indexed = false }, title, "zoomed" },
			tab_inactive = { { "index", zero_indexed = false }, title, "output" },
			tabline_x = { { "cpu", throttle = 30 } },
			tabline_y = { "workspace" },
			tabline_z = { "domain" },
		},
		-- The workspace extension calls gui_window() before a newly created
		-- unix-domain window is associated with the GUI. Leave it disabled.
		extensions = { "resurrect" },
	})
	tabline.apply_to_config(config)
end

return M
