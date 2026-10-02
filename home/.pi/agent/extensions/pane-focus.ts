/**
 * Hide the prompt block cursor while this pane/window is not focused.
 *
 * Pi's editor draws a reverse-video block cursor whenever the editor component
 * has TUI focus, which is always true in interactive mode. In regular TUI mode
 * pi never enables terminal focus reporting, so it cannot tell that the whole
 * pane is inactive. This extension enables DECSET 1004 itself, consumes the
 * focus in/out reports, and strips the block cursor from the editor render while
 * the pane is unfocused.
 *
 * Requires `set -g focus-events on` in ~/.tmux.conf for tmux panes.
 */
import { CustomEditor, type ExtensionAPI, type KeybindingsManager } from "@earendil-works/pi-coding-agent";
import type { EditorTheme, TUI } from "@earendil-works/pi-tui";

const ENABLE_FOCUS_REPORTING = "\x1b[?1004h";
const DISABLE_FOCUS_REPORTING = "\x1b[?1004l";
const FOCUS_IN = "\x1b[I";
const FOCUS_OUT = "\x1b[O";

/** Reverse-video run emitted by Editor for the fake cursor. */
const FAKE_CURSOR = /\x1b\[7m(.*?)\x1b\[0m/;

let paneFocused = true;
const editors = new Set<FocusAwareEditor>();

class FocusAwareEditor extends CustomEditor {
	readonly terminal: TUI["terminal"];

	constructor(tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) {
		super(tui, theme, keybindings);
		this.terminal = tui.terminal;
		this.terminal.write(ENABLE_FOCUS_REPORTING);
		editors.add(this);
	}

	render(width: number): string[] {
		const lines = super.render(width);
		if (paneFocused) return lines;
		// The cursor is the first reverse-video run in the editor output;
		// anything later belongs to the autocomplete selection highlight.
		// Replacing the run with its plain grapheme keeps the visible width
		// unchanged, so layout does not shift.
		const index = lines.findIndex((line) => line.includes("\x1b[7m"));
		if (index === -1) return lines;
		const patched = [...lines];
		patched[index] = lines[index]!.replace(FAKE_CURSOR, "$1");
		return patched;
	}

	requestRender(): void {
		this.tui.requestRender();
	}

	dispose(): void {
		this.terminal.write(DISABLE_FOCUS_REPORTING);
		editors.delete(this);
	}
}

function setPaneFocused(focused: boolean): void {
	if (paneFocused === focused) return;
	paneFocused = focused;
	for (const editor of editors) editor.requestRender();
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setEditorComponent((tui, theme, keybindings) => new FocusAwareEditor(tui, theme, keybindings));

		ctx.ui.onTerminalInput((data) => {
			if (!data.includes(FOCUS_IN) && !data.includes(FOCUS_OUT)) return undefined;

			// Batched input can carry a focus report alongside real keys, so take
			// the last report seen and forward whatever remains.
			let focused = paneFocused;
			for (let index = 0; index < data.length; index++) {
				if (data.startsWith(FOCUS_IN, index)) focused = true;
				else if (data.startsWith(FOCUS_OUT, index)) focused = false;
			}
			setPaneFocused(focused);

			const rest = data.split(FOCUS_IN).join("").split(FOCUS_OUT).join("");
			return rest.length === 0 ? { consume: true } : { data: rest };
		});
	});

	pi.on("session_shutdown", () => {
		for (const editor of editors) editor.dispose();
	});
}
