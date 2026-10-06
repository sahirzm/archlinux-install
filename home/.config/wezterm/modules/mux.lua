-- tmux-style persistence: the GUI is only a client of a background
-- wezterm-mux-server. Closing the window (or LEADER d) detaches; panes keep
-- running and the next `wezterm` launch re-attaches to them.
local wezterm = require("wezterm")

local M = {}

-- ---------------------------------------------------------------------------
-- Remote host: the long-lived (tmux-replacement) session lives HERE.
-- From the laptop, WezTerm's GUI attaches to the wezterm-mux-server running on
-- the remote host. Its embedded ssh reads ~/.ssh/config and honors it --
-- no extra plumbing. The mux server is
-- daemonized and survives network drops / closing the laptop lid; reconnecting
-- re-attaches to the same tabs, panes, and running processes.
-- ---------------------------------------------------------------------------
function M.apply(config)
	-- Local background mux server (persistence on THIS machine).
	-- plain `wezterm` == `wezterm connect unix` (starts the mux server if needed).
	config.default_gui_startup_args = { "connect", "unix" }
	-- GUI-only default; the standalone server still uses its local domain.
	-- Plugins/command-palette spawns must also go into the persistent server.
	config.default_domain = "unix"

	-- tmux: default-shell /bin/zsh
	config.default_prog = { "/bin/zsh", "-l" }

	config.unix_domains = {
		-- Local persistence on whichever machine runs this config.
		{ name = "unix" },

	}
end

return M
