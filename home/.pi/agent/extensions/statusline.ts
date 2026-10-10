/**
 * Pi status-line footer — mirrors ccstatusline settings.json layout
 *
 * Segments (left → right):
 *   model · context-length · thinking-effort · cost · git-branch · git-changes · session-id · cwd
 *
 * Each segment is an independent pill:  content
 * Catppuccin Mocha colors + Nerd Font icons.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import { execSync } from "child_process";
import { randomBytes } from "crypto";
import * as os from "os";
import * as path from "path";

// ── Nerd Font glyphs ──────────────────────────────────────────────────────────
const CAP_LEFT = "\uE0B6"; // rounded left cap
const CAP_RIGHT = "\uE0B4"; // rounded right cap
const CAP_JOIN = "\uE0B0"; // powerline join / forward slant

const ICON_MODEL = "\uF2DB"; // nf-fa-microchip
const ICON_TOKENS = "\uF0E7"; // nf-fa-bolt (context)
const ICON_EXCHANGE = "\uF0EC"; // nf-fa-exchange (session I/O)
const ICON_THINKING = "\uF0EB"; // nf-fa-lightbulb_o
const ICON_COST = "";
const ICON_BRANCH = "\uE0A0"; // nf-pl-branch
const ICON_STAGED = "\uF046"; // nf-fa-check_square_o (staged)
const ICON_MODIFIED = "\uF040"; // nf-fa-pencil (modified)
const ICON_DELETED = "\uF014"; // nf-fa-trash_o (deleted)
const ICON_NEW = "\uF067"; // nf-fa-plus (new/untracked)
const ICON_FOLDER = "\uF07C"; // nf-fa-folder_open
const ICON_CONTAINER = "\uF308"; // nf-linux-docker
const ICON_SESSION = "\uF1DA"; // nf-fa-history (resume)
const ICON_BG = "\uF110"; // nf-fa-spinner

// ── Catppuccin Mocha palette (truecolor ANSI) ─────────────────────────────────
function bg(r: number, g: number, b: number) {
	return `\x1b[48;2;${r};${g};${b}m`;
}
function fg(r: number, g: number, b: number) {
	return `\x1b[38;2;${r};${g};${b}m`;
}

const C = {
	bgPeach: bg(250, 179, 135), // peach    #fab387 — pi logo
	bgSky: bg(137, 220, 235), // sky      #89dceb — model
	bgOverlay: bg(88, 91, 112), // overlay0 #585b70 — context
	bgSapphire: bg(116, 199, 236), // sapphire #74c7ec — session I/O
	bgTeal: bg(148, 226, 213), // teal     #94e2d5 — thinking
	bgGreen: bg(166, 227, 161), // green    #a6e3a1 — cost
	bgMauve: bg(203, 166, 247), // mauve    #cba6f7 — branch
	bgYellow: bg(249, 226, 175), // yellow   #f9e2af — changes
	bgRed: bg(243, 139, 168), // red      #f38ba8 — deletions
	bgBlue: bg(137, 180, 250), // blue     #89b4fa — cwd
	bgPink: bg(245, 194, 231), // pink     #f5c2e7 — dockerpi container
	bgLavender: bg(180, 190, 254), // lavender #b4befe — session id

	fgDark: fg(30, 30, 46), // base  #1e1e2e — text on bright bg
	fgLight: fg(205, 214, 244), // text  #cdd6f4 — text on dark bg

	reset: "\x1b[0m",
	bold: "\x1b[1m",
};

function bgToFg(bgEsc: string): string {
	return bgEsc.replace("\x1b[48;", "\x1b[38;");
}

// ── Pill renderer ─────────────────────────────────────────────────────────────
interface PillSpec {
	bg: string;
	fg: string;
	content: string;
}

/** Build a pill spec. */
function pill(bgEsc: string, fgEsc: string, content: string): PillSpec {
	return { bg: bgEsc, fg: fgEsc, content };
}

/** Render pills as one connected run with rounded outer caps and slanted joins. */
function renderPills(pills: PillSpec[]): string {
	if (pills.length === 0) return "";

	let out = `${bgToFg(pills[0].bg)}${CAP_LEFT}${C.reset}`;
	for (let i = 0; i < pills.length; i++) {
		const current = pills[i];
		out += `${current.bg}${current.fg} ${current.content} ${C.reset}`;
		if (i < pills.length - 1) {
			const next = pills[i + 1];
			out += `${next.bg}${bgToFg(current.bg)}${CAP_JOIN}${C.reset}`;
		}
	}
	out += `${bgToFg(pills[pills.length - 1].bg)}${CAP_RIGHT}${C.reset}`;
	return out;
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function shortenPath(p: string): string {
	const home = os.homedir();
	if (p.startsWith(home)) p = "~" + p.slice(home.length);
	const parts = p.split(path.sep).filter(Boolean);
	if (parts.length <= 3)
		return (p.startsWith("~") ? "~/" : "/") + parts.join("/");
	return "~/" + parts.slice(-2).join("/");
}

function gitBranch(cwd: string): string | null {
	try {
		return (
			execSync("git rev-parse --abbrev-ref HEAD", {
				cwd,
				encoding: "utf8",
				stdio: ["pipe", "pipe", "pipe"],
			}).trim() || null
		);
	} catch {
		return null;
	}
}

interface GitStatus {
	stagedNew: number; // A in index
	stagedModified: number; // M in index
	stagedDeleted: number; // D in index
	wtModified: number; // M in worktree
	wtDeleted: number; // D in worktree
	untracked: number; // ??
}

function gitStatus(cwd: string): GitStatus | null {
	try {
		const out = execSync("git status --porcelain=v1", {
			cwd,
			encoding: "utf8",
			stdio: ["pipe", "pipe", "pipe"],
		});
		if (!out.trim()) return null;

		const s: GitStatus = {
			stagedNew: 0,
			stagedModified: 0,
			stagedDeleted: 0,
			wtModified: 0,
			wtDeleted: 0,
			untracked: 0,
		};
		for (const line of out.trim().split("\n")) {
			const x = line[0]; // index
			const y = line[1]; // worktree
			if (x === "A") s.stagedNew++;
			if (x === "M") s.stagedModified++;
			if (x === "D") s.stagedDeleted++;
			if (y === "M") s.wtModified++;
			if (y === "D") s.wtDeleted++;
			if (x === "?" && y === "?") s.untracked++;
		}
		const total =
			s.stagedNew +
			s.stagedModified +
			s.stagedDeleted +
			s.wtModified +
			s.wtDeleted +
			s.untracked;
		return total > 0 ? s : null;
	} catch {
		return null;
	}
}

const THINKING_LABEL: Record<string, string> = {
	off: "off",
	minimal: "min",
	low: "low",
	medium: "med",
	high: "high",
	xhigh: "max",
};

const THINKING_ICON: Record<string, string> = {
	off: "\uF10C", // nf-fa-circle_o (empty)
	minimal: "\uF111", // nf-fa-circle (faint)
	low: "\uF111",
	medium: "\uF111",
	high: "\uF111",
	xhigh: "\uF111",
};

// ── Background tasks (pi-background-tasks EventBus v1) ────────────────────────
// Ownership comes from the in-process EventBus (`pi.events`): only this
// session's pi-background-tasks registry answers, so the count is scoped to
// tasks this session owns. Scanning the shared on-disk task directory cannot
// do that — pi is PID 1 in every dockerpi container sharing a bind mount, and
// crashed sessions leave stale "running" metadata behind.
const BG_REQUEST_CHANNEL = "pi-background-tasks:request:v1";
const BG_RESPONSE_CHANNEL = "pi-background-tasks:response:v1";
const BG_TERMINAL_CHANNEL = "pi-background-tasks:terminal:v1";
const BG_REQUEST_SCHEMA = "pi-background-tasks.extension-request.v1";
const BG_RESPONSE_SCHEMA = "pi-background-tasks.extension-response.v1";
const BG_QUERY_TIMEOUT_MS = 500;

// request_id must never repeat: per-process nonce + monotonic counter.
const BG_REQUEST_NONCE = randomBytes(8).toString("hex");
let bgRequestSeq = 0;

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

/**
 * Ask this session's pi-background-tasks service for its tasks and count the
 * running ones (agent tasks included). Resolves `null` on timeout, `ok:false`,
 * a malformed matching frame, emit failure, or abort. Responses to other
 * request ids are ignored. The listener and timer are always released.
 */
function queryOwnRunningBgTasks(
	pi: ExtensionAPI,
	signal?: AbortSignal,
): Promise<number | null> {
	return new Promise((resolve) => {
		if (signal?.aborted) {
			resolve(null);
			return;
		}
		const requestId = `statusline-${BG_REQUEST_NONCE}-${++bgRequestSeq}`;
		let settled = false;
		let off: (() => void) | undefined;
		let timer: ReturnType<typeof setTimeout> | undefined;

		const finish = (value: number | null) => {
			if (settled) return;
			settled = true;
			if (timer !== undefined) clearTimeout(timer);
			off?.();
			signal?.removeEventListener("abort", onAbort);
			resolve(value);
		};
		const onAbort = () => finish(null);

		try {
			off = pi.events.on(BG_RESPONSE_CHANNEL, (frame) => {
				if (!isRecord(frame) || frame.request_id !== requestId) return;
				if (frame.schema_version !== BG_RESPONSE_SCHEMA || frame.ok !== true) {
					finish(null);
					return;
				}
				const result = frame.result;
				const tasks = isRecord(result) ? result.tasks : undefined;
				if (!Array.isArray(tasks)) {
					finish(null);
					return;
				}
				finish(
					tasks.filter((t) => isRecord(t) && t.status === "running").length,
				);
			});
			timer = setTimeout(() => finish(null), BG_QUERY_TIMEOUT_MS);
			timer.unref?.();
			signal?.addEventListener("abort", onAbort, { once: true });
			pi.events.emit(BG_REQUEST_CHANNEL, {
				schema_version: BG_REQUEST_SCHEMA,
				request_id: requestId,
				operation: "status",
				payload: {},
			});
		} catch {
			finish(null);
		}
	});
}

// ── Extension ─────────────────────────────────────────────────────────────────
export default function (pi: ExtensionAPI) {
	// Track current thinking level reactively
	let currentThinkingLevel = "off";

	pi.on("thinking_level_select", (event) => {
		currentThinkingLevel = event.level;
	});

	pi.on("session_start", (_event, ctx) => {
		// Read initial level once runtime is ready
		currentThinkingLevel = pi.getThinkingLevel();

		// Defer footer registration so it runs AFTER all other session_start handlers.
		// pi-crew (a package extension) also registers session_start and installs its
		// own footer — since packages load after user extensions, pi-crew's handler
		// fires after ours and would override it.  setTimeout(fn, 0) pushes our
		// setFooter call to the next microtask so we always win.
		setTimeout(() => {
			let bgActive = true;
			let bgQueryPending = false;
			let bgAbort: AbortController | undefined;

			const hideBgWidget = () => {
				try {
					ctx.ui.setWidget("bg-statusline", undefined);
				} catch {
					// UI may already be torn down
				}
			};

			const updateBgWidget = async () => {
				if (!bgActive || bgQueryPending) return;
				bgQueryPending = true;
				const abort = new AbortController();
				bgAbort = abort;
				try {
					const running = await queryOwnRunningBgTasks(pi, abort.signal);
					if (abort.signal.aborted || !bgActive) return;
					if (running === null || running <= 0) {
						hideBgWidget();
						return;
					}
					const bgPills = [
						pill(C.bgOverlay, C.fgLight, `${ICON_BG} bg`),
						pill(C.bgGreen, C.fgDark, `▶ ${running} running`),
						pill(C.bgBlue, C.fgDark, `/tasks`),
					];
					ctx.ui.setWidget(
						"bg-statusline",
						[` ${renderPills(bgPills)}`],
						{ placement: "aboveEditor" },
					);
				} catch {
					hideBgWidget();
				} finally {
					bgQueryPending = false;
					if (bgAbort === abort) bgAbort = undefined;
				}
			};
			void updateBgWidget();

			ctx.ui.setFooter((tui, _theme, footerData) => {
				bgActive = true;
				const unsubBranch = footerData.onBranchChange(() =>
					tui.requestRender(),
				);
				const unsubBgTerminal = pi.events.on(BG_TERMINAL_CHANNEL, () => {
					void updateBgWidget();
				});
				const refreshHandle = setInterval(() => {
					tui.requestRender();
					void updateBgWidget();
				}, 2000);
				refreshHandle.unref?.();

				// Git cache (5 s TTL)
				let lastGitMs = 0;
				let cachedBranch: string | null = null;
				let cachedStatus: GitStatus | null = null;

				function getGit(cwd: string) {
					const now = Date.now();
					if (now - lastGitMs > 5000) {
						cachedBranch = gitBranch(cwd);
						cachedStatus = gitStatus(cwd);
						lastGitMs = now;
					}
					return { branch: cachedBranch, status: cachedStatus };
				}

				return {
					dispose() {
						unsubBranch();
						unsubBgTerminal();
						clearInterval(refreshHandle);
						bgActive = false;
						bgAbort?.abort();
						hideBgWidget();
					},
					invalidate() {},

					render(width: number): string[] {
						const cwd = process.cwd();

						// ── Model ─────────────────────────────────────────────────────────
						const modelId = ctx.model?.id ?? "no-model";
						const modelShort = modelId
							.replace(/^.*\//, "")
							.replace(/^claude-/, "")
							.replace(/-\d{8}$/, "");

						// ── Tokens & cost ─────────────────────────────────────────────────
						let inputTok = 0,
							outputTok = 0,
							costTotal = 0;
						for (const e of ctx.sessionManager.getBranch()) {
							if (e.type === "message" && e.message.role === "assistant") {
								const m = e.message as AssistantMessage;
								inputTok += m.usage.input;
								outputTok += m.usage.output;
								costTotal += m.usage.cost.total;
							}
						}
						const fmtK = (n: number) =>
							n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`;
						// Current context-window usage — same estimate Pi uses for
						// compaction. tokens/percent are null right after compaction
						// until the next LLM response.
						const usage = ctx.getContextUsage();
						const windowTok =
							usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
						const ctxStr =
							usage && usage.tokens !== null && usage.percent !== null
								? `${fmtK(usage.tokens)}/${fmtK(windowTok)} ${usage.percent.toFixed(1)}%`
								: `?/${fmtK(windowTok)}`;
						const costStr = `$${costTotal.toFixed(3)}`;

						// ── Thinking level ────────────────────────────────────────────────
						const thinkingLabel =
							THINKING_LABEL[currentThinkingLevel] ?? currentThinkingLevel;
						const thinkingIcon =
							THINKING_ICON[currentThinkingLevel] ?? ICON_THINKING;

						// ── Git ───────────────────────────────────────────────────────────
						const { branch, status } = getGit(cwd);

						// ── CWD ───────────────────────────────────────────────────────────
						const cwdShort = shortenPath(cwd);

						// ── Build pills ───────────────────────────────────────────────────
						const pills: string[] = [];

						// 0. Pi logo — peach pill
						pills.push(
							pill(
								C.bgPeach,
								`${C.bold}${C.fgDark}`,
								`π`,
							),
						);

						// 1. Model
						pills.push(
							pill(
								C.bgSky,
								C.fgDark,
								`${C.bold}${ICON_MODEL} ${modelShort}${C.reset}${C.bgSky}${C.fgDark}`,
							),
						);

						// 2. Context / tokens
						pills.push(
							pill(C.bgOverlay, C.fgLight, `${ICON_TOKENS} ${ctxStr}`),
						);

						// 2b. Session token totals (cumulative input/output)
					pills.push(
						pill(
							C.bgSapphire,
							C.fgDark,
							`${ICON_EXCHANGE} ${fmtK(inputTok)}↑ ${fmtK(outputTok)}↓`,
						),
					);

					// 3. Thinking level (always shown)
						pills.push(
							pill(C.bgTeal, C.fgDark, `${thinkingIcon} ${thinkingLabel}`),
						);

						// 4. Cost
						pills.push(pill(C.bgGreen, C.fgDark, costStr));

						// 5. Git branch
						if (branch) {
							pills.push(pill(C.bgMauve, C.fgDark, `${ICON_BRANCH} ${branch}`));
						}

						// 6. Git status — separate pills for staged, worktree, untracked, deleted
						if (status) {
							// Staged changes (new + modified together)
							const stagedCount = status.stagedNew + status.stagedModified;
							if (stagedCount > 0) {
								const parts: string[] = [];
								if (status.stagedNew)
									parts.push(`${ICON_NEW} ${status.stagedNew}`);
								if (status.stagedModified)
									parts.push(`${ICON_MODIFIED} ${status.stagedModified}`);
								pills.push(pill(C.bgGreen, C.fgDark, parts.join("  ")));
							}

							// Staged deletions
							if (status.stagedDeleted > 0) {
								pills.push(
									pill(
										C.bgRed,
										C.fgDark,
										`${ICON_DELETED} ${status.stagedDeleted}`,
									),
								);
							}

							// Worktree modifications
							if (status.wtModified > 0) {
								pills.push(
									pill(
										C.bgYellow,
										C.fgDark,
										`${ICON_MODIFIED} ${status.wtModified}`,
									),
								);
							}

							// Worktree deletions
							if (status.wtDeleted > 0) {
								pills.push(
									pill(C.bgRed, C.fgDark, `${ICON_DELETED} ${status.wtDeleted}`),
								);
							}

							// Untracked
							if (status.untracked > 0) {
								pills.push(
									pill(
										C.bgOverlay,
										C.fgLight,
										`${ICON_NEW} ${status.untracked}`,
									),
								);
							}
						}

						// 7. dockerpi container — the name to `docker exec -it <name> zsh` into
						const containerName = process.env.DOCKERPI_CONTAINER;
						if (containerName) {
							pills.push(
								pill(C.bgPink, C.fgDark, `${ICON_CONTAINER} ${containerName}`),
							);
						}

						// 8. Session id — first 8 chars are enough for `pi --session <id>`
						const sessionShort = ctx.sessionManager
							.getSessionId()
							.slice(0, 8);
						pills.push(
							pill(C.bgLavender, C.fgDark, `${ICON_SESSION} ${sessionShort}`),
						);

						// 9. CWD
						pills.push(
							pill(
								C.bgBlue,
								C.fgDark,
								`${C.bold}${ICON_FOLDER} ${cwdShort}${C.reset}${C.bgBlue}${C.fgDark}`,
							),
						);

						return [truncateToWidth(` ${renderPills(pills)}`, width)];
					},
				};
			});
		}, 0); // end deferred footer install
	});
}
