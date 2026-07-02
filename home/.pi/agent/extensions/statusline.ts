/**
 * Pi status-line footer — mirrors ccstatusline settings.json layout
 *
 * Segments (left → right):
 *   model · context-length · thinking-effort · cost · git-branch · git-changes · cwd
 *
 * Each segment is an independent pill:  content 
 * Catppuccin Mocha colors + Nerd Font icons.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import { execSync } from "child_process";
import * as os from "os";
import * as path from "path";

// ── Nerd Font glyphs ──────────────────────────────────────────────────────────
const CAP_LEFT  = "\uE0B6"; // rounded left cap  
const CAP_RIGHT = "\uE0B4"; // rounded right cap 

const ICON_MODEL    = "\uF2DB"; // nf-fa-microchip        
const ICON_TOKENS   = "\uF0E7"; // nf-fa-bolt (context)   
const ICON_THINKING = "\uF0EB"; // nf-fa-lightbulb_o      
const ICON_COST     = "\uF155"; // nf-fa-usd (cost)       
const ICON_BRANCH   = "\uE0A0"; // nf-pl-branch           
const ICON_STAGED   = "\uF046"; // nf-fa-check_square_o (staged)  
const ICON_MODIFIED = "\uF040"; // nf-fa-pencil (modified)        
const ICON_DELETED  = "\uF014"; // nf-fa-trash_o (deleted)        
const ICON_NEW      = "\uF067"; // nf-fa-plus (new/untracked)     
const ICON_FOLDER   = "\uF07C"; // nf-fa-folder_open      

// ── Catppuccin Mocha palette (truecolor ANSI) ─────────────────────────────────
function bg(r: number, g: number, b: number) { return `\x1b[48;2;${r};${g};${b}m`; }
function fg(r: number, g: number, b: number) { return `\x1b[38;2;${r};${g};${b}m`; }

const C = {
  bgPeach:   bg(250, 179, 135), // peach    #fab387 — pi logo
  bgSky:     bg(137, 220, 235), // sky      #89dceb — model
  bgOverlay: bg( 88,  91, 112), // overlay0 #585b70 — context
  bgTeal:    bg(148, 226, 213), // teal     #94e2d5 — thinking
  bgGreen:   bg(166, 227, 161), // green    #a6e3a1 — cost
  bgMauve:   bg(203, 166, 247), // mauve    #cba6f7 — branch
  bgYellow:  bg(249, 226, 175), // yellow   #f9e2af — changes
  bgRed:     bg(243, 139, 168), // red      #f38ba8 — deletions
  bgBlue:    bg(137, 180, 250), // blue     #89b4fa — cwd

  fgDark:  fg( 30,  30,  46), // base  #1e1e2e — text on bright bg
  fgLight: fg(205, 214, 244), // text  #cdd6f4 — text on dark bg

  reset: "\x1b[0m",
  bold:  "\x1b[1m",
};

function bgToFg(bgEsc: string): string {
  return bgEsc.replace("\x1b[48;", "\x1b[38;");
}

// ── Pill renderer ─────────────────────────────────────────────────────────────
/** Render a single rounded pill:  content  */
function pill(bgEsc: string, fgEsc: string, content: string): string {
  const capFg = bgToFg(bgEsc);
  return `${capFg}${CAP_LEFT}${C.reset}${bgEsc}${fgEsc} ${content} ${C.reset}${capFg}${CAP_RIGHT}${C.reset}`;
}

/** Render all pills joined by a single space. */
function renderPills(pills: string[]): string {
  return pills.join(" ");
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function shortenPath(p: string): string {
  const home = os.homedir();
  if (p.startsWith(home)) p = "~" + p.slice(home.length);
  const parts = p.split(path.sep).filter(Boolean);
  if (parts.length <= 3) return (p.startsWith("~") ? "~/" : "/") + parts.join("/");
  return "~/" + parts.slice(-2).join("/");
}

function gitBranch(cwd: string): string | null {
  try {
    return execSync("git rev-parse --abbrev-ref HEAD", {
      cwd, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"],
    }).trim() || null;
  } catch { return null; }
}

interface GitStatus {
  stagedNew:      number; // A in index
  stagedModified: number; // M in index
  stagedDeleted:  number; // D in index
  wtModified:     number; // M in worktree
  wtDeleted:      number; // D in worktree
  untracked:      number; // ??
}

function gitStatus(cwd: string): GitStatus | null {
  try {
    const out = execSync("git status --porcelain=v1", {
      cwd, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"],
    });
    if (!out.trim()) return null;

    const s: GitStatus = { stagedNew: 0, stagedModified: 0, stagedDeleted: 0, wtModified: 0, wtDeleted: 0, untracked: 0 };
    for (const line of out.trim().split("\n")) {
      const x = line[0]; // index
      const y = line[1]; // worktree
      if (x === "A")  s.stagedNew++;
      if (x === "M")  s.stagedModified++;
      if (x === "D")  s.stagedDeleted++;
      if (y === "M")  s.wtModified++;
      if (y === "D")  s.wtDeleted++;
      if (x === "?" && y === "?") s.untracked++;
    }
    const total = s.stagedNew + s.stagedModified + s.stagedDeleted + s.wtModified + s.wtDeleted + s.untracked;
    return total > 0 ? s : null;
  } catch { return null; }
}

const THINKING_LABEL: Record<string, string> = {
  off:     "off",
  minimal: "min",
  low:     "low",
  medium:  "med",
  high:    "high",
  xhigh:   "max",
};

const THINKING_ICON: Record<string, string> = {
  off:     "\uF10C",  // nf-fa-circle_o (empty)
  minimal: "\uF111",  // nf-fa-circle (faint)
  low:     "\uF111",
  medium:  "\uF111",
  high:    "\uF111",
  xhigh:   "\uF111",
};

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

    ctx.ui.setFooter((tui, _theme, footerData) => {
      const unsubBranch = footerData.onBranchChange(() => tui.requestRender());

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
        dispose: unsubBranch,
        invalidate() {},

        render(width: number): string[] {
          const cwd = process.cwd();

          // ── Model ─────────────────────────────────────────────────────────
          const modelId    = ctx.model?.id ?? "no-model";
          const modelShort = modelId
            .replace(/^.*\//, "")
            .replace(/^claude-/, "")
            .replace(/-\d{8}$/, "");

          // ── Tokens & cost ─────────────────────────────────────────────────
          let inputTok = 0, outputTok = 0, costTotal = 0;
          for (const e of ctx.sessionManager.getBranch()) {
            if (e.type === "message" && e.message.role === "assistant") {
              const m = e.message as AssistantMessage;
              inputTok  += m.usage.input;
              outputTok += m.usage.output;
              costTotal += m.usage.cost.total;
            }
          }
          const fmtK    = (n: number) => n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`;
          const ctxStr  = `${fmtK(inputTok)}↑ ${fmtK(outputTok)}↓`;
          const costStr = `$${costTotal.toFixed(3)}`;

          // ── Thinking level ────────────────────────────────────────────────
          const thinkingLabel = THINKING_LABEL[currentThinkingLevel] ?? currentThinkingLevel;
          const thinkingIcon  = THINKING_ICON[currentThinkingLevel] ?? ICON_THINKING;

          // ── Git ───────────────────────────────────────────────────────────
          const { branch, status } = getGit(cwd);

          // ── CWD ───────────────────────────────────────────────────────────
          const cwdShort = shortenPath(cwd);

          // ── Build pills ───────────────────────────────────────────────────
          const pills: string[] = [];

          // 0. Pi logo — peach pill
          pills.push(pill(C.bgPeach, C.fgDark, `${C.bold}π${C.reset}${C.bgPeach}${C.fgDark}`));

          // 1. Model
          pills.push(pill(C.bgSky, C.fgDark,
            `${C.bold}${ICON_MODEL} ${modelShort}${C.reset}${C.bgSky}${C.fgDark}`));

          // 2. Context / tokens
          pills.push(pill(C.bgOverlay, C.fgLight, `${ICON_TOKENS} ${ctxStr}`));

          // 3. Thinking level (always shown)
          pills.push(pill(C.bgTeal, C.fgDark, `${thinkingIcon} ${thinkingLabel}`));

          // 4. Cost
          pills.push(pill(C.bgGreen, C.fgDark, `${ICON_COST} ${costStr}`));

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
              if (status.stagedNew)      parts.push(`${ICON_NEW}${status.stagedNew}`);
              if (status.stagedModified) parts.push(`${ICON_MODIFIED}${status.stagedModified}`);
              pills.push(pill(C.bgGreen, C.fgDark, parts.join("  ")));
            }

            // Staged deletions
            if (status.stagedDeleted > 0) {
              pills.push(pill(C.bgRed, C.fgDark, `${ICON_DELETED}${status.stagedDeleted}`));
            }

            // Worktree modifications
            if (status.wtModified > 0) {
              pills.push(pill(C.bgYellow, C.fgDark, `${ICON_MODIFIED}${status.wtModified}`));
            }

            // Worktree deletions
            if (status.wtDeleted > 0) {
              pills.push(pill(C.bgRed, C.fgDark, `${ICON_DELETED}${status.wtDeleted}`));
            }

            // Untracked
            if (status.untracked > 0) {
              pills.push(pill(C.bgOverlay, C.fgLight, `${ICON_NEW}${status.untracked}`));
            }
          }

          // 7. CWD
          pills.push(pill(C.bgBlue, C.fgDark,
            `${C.bold}${ICON_FOLDER} ${cwdShort}${C.reset}${C.bgBlue}${C.fgDark}`));

          // Top margin: one blank line above the pills
          return ["", truncateToWidth(renderPills(pills), width)];
        },
      };
    });
  });
}
