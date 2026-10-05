-- WezTerm config. Replaces kitty (terminal) and tmux (multiplexer).
-- Modules live in ./modules; WezTerm puts this directory on package.path.
-- Not-yet-ported tmux features: ./wezterm_pending_items
local wezterm = require("wezterm")
local config = wezterm.config_builder()

for _, module in ipairs({ "appearance", "mux", "keys", "statusbar", "session" }) do
	require("modules." .. module).apply(config)
end

return config
