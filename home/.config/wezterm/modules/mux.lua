-- tmux-style persistence: the GUI is only a client of a background
-- wezterm-mux-server. Closing the window (or LEADER d) detaches; panes keep
-- running and the next `wezterm` launch re-attaches to them.
local wezterm = require("wezterm")

local M = {}

-- ---------------------------------------------------------------------------

return M
