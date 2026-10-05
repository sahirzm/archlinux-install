-- tmux windows -> WezTerm tabs; tmux sessions -> WezTerm workspaces.
-- LEADER means Ctrl-a. Deferred bindings are listed in ../wezterm_pending_items.
local wezterm = require("wezterm")
local act = wezterm.action
local plugins = require("modules.plugins")
local M = {}

function M.apply(config)
	config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 3000 }
	-- Allow applications to request enhanced key reporting (e.g. Shift-Enter).
	config.enable_kitty_keyboard = true

	config.keys = {
		{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
		{ key = "l", mods = "LEADER|CTRL", action = act.SendKey({ key = "l", mods = "CTRL" }) },
		{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "%", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = '"', mods = "LEADER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
		{ key = "o", mods = "LEADER", action = act.ActivatePaneDirection("Next") },
		{ key = "q", mods = "LEADER", action = act.PaneSelect({ alphabet = "123456789" }) },
		{ key = "!", mods = "LEADER|SHIFT", action = wezterm.action_callback(function(_, pane)
			local tab = pane:move_to_new_tab()
			tab:activate()
		end) },

		{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
		{ key = "a", mods = "LEADER", action = act.ActivateLastTab },
		{ key = "l", mods = "LEADER", action = act.ActivateLastTab },
		-- p/C-p stay reserved for the deferred pomodoro plugin, as in tmux.conf.
		{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "&", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
		{ key = ",", mods = "LEADER", action = act.PromptInputLine({
			description = "Rename tab:",
			action = wezterm.action_callback(function(window, _, name)
				if name then
					window:active_tab():set_title(name)
				end
			end),
		}) },
		{ key = "$", mods = "LEADER|SHIFT", action = act.PromptInputLine({
			description = "Rename workspace:",
			action = wezterm.action_callback(function(window, _, name)
				if name and name:match("%S") then
					wezterm.mux.rename_workspace(window:active_workspace(), name)
				end
			end),
		}) },

		-- g now chooses workspaces/zoxide directories, not individual panes.
		{ key = "g", mods = "LEADER", action = plugins.workspace_switcher.switch_workspace() },
		{ key = "L", mods = "LEADER|SHIFT", action = plugins.workspace_switcher.switch_to_prev_workspace() },
		{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
		{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|TABS|WORKSPACES" }) },
		{ key = "(", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(-1) },
		{ key = ")", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(1) },
		{ key = "n", mods = "LEADER|CTRL", action = act.PromptInputLine({
			description = "Go to / Create workspace:",
			action = wezterm.action_callback(function(window, pane, name)
				if name and name:match("%S") then
					window:perform_action(act.SwitchToWorkspace({
						name = name,
						spawn = { domain = { DomainName = pane:get_domain_name() } },
					}), pane)
				end
			end),
		}) },
		{ key = "d", mods = "LEADER", action = act.DetachDomain("CurrentPaneDomain") },
		{ key = ":", mods = "LEADER|SHIFT", action = act.ActivateCommandPalette },
		{ key = "?", mods = "LEADER|SHIFT", action = act.ActivateCommandPalette },
		{ key = "~", mods = "LEADER|SHIFT", action = act.ShowDebugOverlay },
		{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },
		{ key = "R", mods = "LEADER|SHIFT", action = act.ReloadConfiguration },

		{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
		{ key = "PageUp", mods = "LEADER", action = act.ActivateCopyMode },
		{ key = "]", mods = "LEADER", action = act.PasteFrom("Clipboard") },
		-- tmux-fastcopy: hint labels + copy to clipboard.
		{ key = "f", mods = "LEADER", action = act.QuickSelect },
		-- tmux-fzf-url: URL hints + open in browser (not an fzf list).
		{ key = "u", mods = "LEADER", action = act.QuickSelectArgs({
			patterns = { [[https?://[^\s<>"'\[\]()]+]] },
			action = wezterm.action_callback(function(window, pane)
				local url = window:get_selection_text_for_pane(pane)
				if url ~= "" then
					wezterm.open_with(url)
				end
			end),
		}) },
		{ key = "Y", mods = "LEADER|SHIFT", action = wezterm.action_callback(function(window, pane)
			local cwd = pane:get_current_working_dir()
			if cwd then
				window:copy_to_clipboard(cwd.file_path)
			end
		end) },
	}

	-- tmux uses 1-based window numbers; WezTerm's actions are 0-based.
	for i = 1, 9 do
		table.insert(config.keys, { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - 1) })
	end

	for key, direction in pairs({ h = "Left", j = "Down", k = "Up", l = "Right" }) do
		table.insert(config.keys, { key = key, mods = "LEADER|ALT", action = act.AdjustPaneSize({ direction, 10 }) })
		local arrow = direction .. "Arrow"
		table.insert(config.keys, { key = arrow, mods = "LEADER", action = act.ActivatePaneDirection(direction) })
		table.insert(config.keys, { key = arrow, mods = "LEADER|CTRL", action = act.AdjustPaneSize({ direction, 1 }) })
		table.insert(config.keys, { key = arrow, mods = "LEADER|ALT", action = act.AdjustPaneSize({ direction, 5 }) })
	end

	-- Use the upstream IS_NVIM integration, which also works over mux domains.
	-- No unprefixed Alt bindings: preserve shell and LazyVim Alt-j/k behavior.
	plugins.smart_splits.apply_to_config(config, {
		direction_keys = { move = { "h", "j", "k", "l" }, resize = {} },
		modifiers = { move = "CTRL" },
		log_level = "error",
	})

	-- kitty: copy_on_select yes. Keep application mouse reporting unchanged.
	config.mouse_bindings = {}
	for streak = 1, 3 do
		table.insert(config.mouse_bindings, {
			event = { Up = { streak = streak, button = "Left" } },
			mods = "NONE",
			action = act.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
		})
	end

	-- Extend the built-in vi-like table rather than recreating it.
	if wezterm.gui then
		local copy = wezterm.gui.default_key_tables().copy_mode
		for _, binding in ipairs(copy) do
			if binding.key == "Enter" then
				binding.action = act.Multiple({ act.CopyTo("ClipboardAndPrimarySelection"), act.CopyMode("Close") })
			end
		end
		table.insert(copy, { key = "/", mods = "NONE", action = act.Search({ CaseSensitiveString = "" }) })
		table.insert(copy, { key = "n", mods = "NONE", action = act.CopyMode("NextMatch") })
		table.insert(copy, { key = "N", mods = "SHIFT", action = act.CopyMode("PriorMatch") })
		config.key_tables = { copy_mode = copy }
	end
end

return M
