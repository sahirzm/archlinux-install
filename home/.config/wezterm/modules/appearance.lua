-- Look & feel carried over from kitty.conf / tmux catppuccin theme.
local wezterm = require("wezterm")

local M = {}

function M.apply(config)
	config.color_scheme = "Catppuccin Mocha"
	config.font = wezterm.font("FiraCode Nerd Font")
	config.font_size = 12

	config.window_decorations = "RESIZE"
	config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

	-- tmux: status-position top; tabline.wez draws the retro tab bar
	config.use_fancy_tab_bar = false
	config.tab_bar_at_bottom = false
	config.hide_tab_bar_if_only_one_tab = false
	config.show_new_tab_button_in_tab_bar = false
	config.tab_max_width = 32

	-- kitty: enable_audio_bell no
	config.audible_bell = "Disabled"

	-- tmux: history-limit 100000
	config.scrollback_lines = 100000
end

return M
