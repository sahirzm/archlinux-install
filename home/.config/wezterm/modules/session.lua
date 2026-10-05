-- Layout backups use the upstream resurrect plugin; live processes and
-- scrollback survive GUI closure in the unix-domain server itself.
local wezterm = require("wezterm")
local resurrect = require("modules.plugins").resurrect
local M = {}

local function save_workspace()
	resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
end

function M.apply(config)
	local state_home = os.getenv("XDG_STATE_HOME") or (wezterm.home_dir .. "/.local/state")
	resurrect.state_manager.change_state_save_dir(state_home .. "/wezterm/resurrect/")
	resurrect.state_manager.set_max_nlines(100000)

	-- Only the GUI can snapshot client workspaces. Do not run two autosave
	-- timers (one in the GUI and one in the mux server), or one per reload.
	wezterm.on("gui-attached", function()
		if not wezterm.GLOBAL.resurrect_periodic_save_started then
			wezterm.GLOBAL.resurrect_periodic_save_started = true
			resurrect.state_manager.periodic_save({
				interval_seconds = 15 * 60,
				save_workspaces = true,
			})
		end
	end)
	wezterm.on("smart_workspace_switcher.workspace_switcher.selected", save_workspace)

	table.insert(config.keys, {
		key = "s", mods = "LEADER|CTRL",
		action = wezterm.action_callback(save_workspace),
	})
	table.insert(config.keys, {
		key = "r", mods = "LEADER|CTRL",
		action = wezterm.action_callback(function(window, pane)
			resurrect.fuzzy_loader.fuzzy_load(window, pane, function(id)
				if not id then
					return
				end
				local name = id:match("([^/]+)%.json$")
				if not name then
					return
				end
				local state = resurrect.state_manager.load_state(name, "workspace")
				if not state.window_states then
					return
				end
				-- Reattach to a live workspace rather than creating duplicate panes.
				for _, live in ipairs(wezterm.mux.get_workspace_names()) do
					if live == state.workspace then
						window:perform_action(wezterm.action.SwitchToWorkspace({ name = live }), pane)
						return
					end
				end
				local existing_windows = {}
				for _, mux_window in ipairs(wezterm.mux.all_windows()) do
					existing_windows[mux_window:window_id()] = true
				end
				resurrect.workspace_state.restore_workspace(state, {
					-- ClientDomain.spawn ignores the requested workspace and uses
					-- the active one. Assign newly restored windows afterwards so
					-- WindowWorkspaceChanged synchronizes the name to the server.
					spawn_in_workspace = false,
					relative = true,
					resize_window = false,
					-- Unix-domain client panes cannot inject saved scrollback.
					restore_text = false,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
				})
				for _, mux_window in ipairs(wezterm.mux.all_windows()) do
					if not existing_windows[mux_window:window_id()] then
						mux_window:set_workspace(state.workspace)
					end
				end
				wezterm.mux.set_active_workspace(state.workspace)
			end, { ignore_tabs = true, ignore_windows = true })
		end),
	})
end

return M
