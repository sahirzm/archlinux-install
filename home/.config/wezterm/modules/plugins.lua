-- Third-party WezTerm plugins (cloned into ~/.local/share/wezterm/plugins on first load).
-- Update with: wezterm.plugin.update_all() from the debug overlay (LEADER ~).
local wezterm = require("wezterm")

return {
	-- status bar (replaces catppuccin/tmux status line + tmux-cpu)
	tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez"),
	-- layout backups (live scrollback persists in the mux server)
	resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm"),
	-- fuzzy workspace/zoxide switcher (replaces the `prefix g` fzf popup)
	workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm"),
	-- seamless C-hjkl between nvim splits and WezTerm panes (replaces vim-tmux-navigator)
	smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim"),
}
