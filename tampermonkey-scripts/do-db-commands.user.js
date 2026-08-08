// ==UserScript==
// @name         DigitalOcean DB Quick Commands
// @namespace    http://tampermonkey.net/
// @version      2.3
// @description  Floating bottom-right psql/pg_dump/scp buttons for DO database pages. Structure-agnostic: parses connection params from page text via regex.
// @author       You
// @match        https://cloud.digitalocean.com/databases*
// @updateURL    https://raw.githubusercontent.com/sahirzm/archlinux-install/main/tampermonkey-scripts/do-db-commands.user.js
// @downloadURL  https://raw.githubusercontent.com/sahirzm/archlinux-install/main/tampermonkey-scripts/do-db-commands.user.js
// @grant        GM_setClipboard
// ==/UserScript==

(() => {
	// ── SVG icons ──────────────────────────────────────────────────────────────
	const ICON_PSQL = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none"
        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="4 17 10 11 4 5"/>
        <line x1="12" y1="19" x2="20" y2="19"/>
    </svg>`;

	const ICON_DUMP = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none"
        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
        <polyline points="7 10 12 15 17 10"/>
        <line x1="12" y1="15" x2="12" y2="3"/>
    </svg>`;

	const ICON_SCP = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none"
        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="17 8 21 12 17 16"/>
        <polyline points="7 8 3 12 7 16"/>
        <line x1="21" y1="12" x2="3" y2="12"/>
    </svg>`;

	// ── Parse connection details from page text (structure-agnostic) ──────────
	// Collects visible text from the page, then extracts connection params.
	// Supports both `key=value` parameter blocks and `postgresql://` URIs.
	//
	// The walker starts at document.body (not <main>) because DO often renders
	// the connection panel in a portal sibling to <main>, and pierces shadow
	// roots because DO uses web components with Shadow DOM — cloneNode/textContent
	// and querySelectorAll do NOT cross shadow boundaries.
	// DO renders each connection param as a separate block element with no
	// whitespace between lines, so a naive text walk concatenates them into
	// `username = doadminpassword = ***host = ...comport = 25060...` and the
	// value regex captures the next key gluing onto the value. Insert a newline
	// at element boundaries so each line is separated, while keeping inline
	// text (e.g. a hyphenated hostname, one text node) intact.
	const SKIP_TAGS = new Set(["SCRIPT", "STYLE", "NOSCRIPT", "SVG", "TEMPLATE"]);
	// DO keeps both Public-network and VPC-network param blocks in the DOM; the
	// inactive tab is display:none. User/Database dropdowns swap the username/database
	// values in place. To read only the currently selected tab, skip hidden subtrees
	// during the walk. offsetParent === null catches display:none (set via class or
	// inline); confirm with getComputedStyle so position:fixed panels aren't skipped.
	function isHiddenEl(el) {
		const tag = el.tagName;
		if (tag === "BODY" || tag === "HTML") return false;
		if (el.hidden || el.getAttribute("aria-hidden") === "true") return true;
		const st = el.style;
		if (st.display === "none" || st.visibility === "hidden" || st.opacity === "0") return true;
		if (el.offsetParent === null) {
			const cs = getComputedStyle(el);
			if (cs.display === "none" || cs.visibility === "hidden") return true;
		}
		return false;
	}
	function getPageText() {
		const parts = [];
		const walk = (node) => {
			if (node.nodeType === 3) {
				const t = node.textContent;
				if (t) parts.push(t);
				return;
			}
			if (node.nodeType !== 1) return;
			const el = node;
			if (SKIP_TAGS.has(el.tagName)) return;
			if (isHiddenEl(el)) return;
			if (el.shadowRoot) {
				for (const c of el.shadowRoot.childNodes) walk(c);
				parts.push("\n");
			}
			let first = true;
			for (const c of el.childNodes) {
				if (c.nodeType === 1) {
					if (!first) parts.push("\n");
					first = false;
				}
				walk(c);
			}
		};
		walk(document.body);
		return parts.join("").replace(/\u00a0/g, " ");
	}

	function parseDetails() {
		const text = getPageText();
		const d = {};

		// 1) Try a postgresql:// URI first — most reliable when present.
		const uri = text.match(
			/postgres(?:ql)?:\/\/([^:\s/]+):([^@\s/]+)@([^:\s/]+):(\d+)\/(\S+?)(?:[?\s]|$)/i,
		);
		if (uri) {
			d.username = uri[1];
			d.password = decodeURIComponent(uri[2]);
			d.host = uri[3];
			d.port = uri[4];
			d.database = uri[5].replace(/[?].*$/, "");
			const ssl = uri[5].match(/sslmode=([A-Za-z0-9]+)/);
			if (ssl) d.sslmode = ssl[1];
		}

		// 2) Scan for key=value pairs anywhere in the text. These override URI
		//    fields when present (e.g. revealed password may differ from masked
		//    value in the URI).
		const keyRe =
			/(^|[^\w-])(host|port|user|username|password|database|dbname|sslmode)\s*[:=]\s*([^\s,;|]+)/gim;
		let m;
		while ((m = keyRe.exec(text)) !== null) {
			const key = m[2].toLowerCase();
			const val = m[3].replace(/^["'`]|["'`]$/g, "").trim();
			if (key === "host") d.host = val;
			else if (key === "port") d.port = val;
			else if (key === "user") d.username = val;
			else if (key === "username") d.username = val;
			else if (key === "password") d.password = val;
			else if (key === "database") d.database = val;
			else if (key === "dbname") d.database = val;
			else if (key === "sslmode") d.sslmode = val;
		}

		return d;
	}

	function isMasked(value) {
		return !value || /^\*+$/.test(value);
	}

	// ── Command builders ───────────────────────────────────────────────────────
	function buildPsqlCmd(d) {
		let cmd = `PGPASSWORD=${d.password} psql -U ${d.username} -h ${d.host} -p ${d.port} -d ${d.database}`;
		if (d.sslmode) cmd += ` --set=sslmode=${d.sslmode}`;
		return cmd;
	}

	let lastDumpTs = null;

	function getUtcTs() {
		const now = new Date();
		const pad = (n) => String(n).padStart(2, "0");
		return `${now.getUTCFullYear()}${pad(now.getUTCMonth() + 1)}${pad(now.getUTCDate())}_${pad(now.getUTCHours())}${pad(now.getUTCMinutes())}`;
	}

	function buildDumpCmd(d) {
		lastDumpTs = getUtcTs();
		return `PGPASSWORD=${d.password} pg_dump -U ${d.username} -h ${d.host} -p ${d.port} -Fc --no-owner ${d.database} > db_dump_${lastDumpTs}.sql`;
	}

	function buildScpCmd(d) {
		const ts = lastDumpTs ?? getUtcTs();
		return `scp jobbersoft@${d.database}.jobbersoft.com:~/db_dump_${ts}.sql dump.sql`;
	}

	// ── Clipboard ──────────────────────────────────────────────────────────────
	function copyText(text) {
		try {
			navigator.clipboard.writeText(text);
		} catch {
			GM_setClipboard(text);
		}
	}

	// ── Toast notification ─────────────────────────────────────────────────────
	function toast(msg, isWarn = false) {
		const el = document.createElement("div");
		el.textContent = msg;
		Object.assign(el.style, {
			position: "fixed",
			bottom: "24px",
			right: "24px",
			background: isWarn ? "#7c3a1e" : "#1a3a5c",
			color: "#fff",
			padding: "10px 16px",
			borderRadius: "6px",
			fontSize: "13px",
			zIndex: "100000",
			boxShadow: "0 4px 14px rgba(0,0,0,0.4)",
			transition: "opacity 0.3s",
			fontFamily: "monospace",
		});
		document.body.append(el);
		setTimeout(() => {
			el.style.opacity = "0";
			setTimeout(() => el.remove(), 300);
		}, 2500);
	}

	// ── Button factory ─────────────────────────────────────────────────────────
	function svgNode(svgMarkup) {
		const doc = new DOMParser().parseFromString(svgMarkup, "image/svg+xml");
		return document.importNode(doc.documentElement, true);
	}

	function makeButton(icon, label, onClick) {
		const btn = document.createElement("button");
		btn.type = "button";
		btn.append(svgNode(icon));
		const span = document.createElement("span");
		span.textContent = label;
		btn.append(span);
		Object.assign(btn.style, {
			display: "inline-flex",
			alignItems: "center",
			gap: "5px",
			background: "transparent",
			border: "1px solid #3d5a80",
			borderRadius: "5px",
			color: "#7eb8f7",
			cursor: "pointer",
			fontSize: "12px",
			padding: "5px 10px",
			fontFamily: "monospace",
			transition: "background 0.15s, color 0.15s",
			whiteSpace: "nowrap",
		});
		btn.addEventListener("mouseenter", () => {
			btn.style.background = "#1a3a5c";
			btn.style.color = "#c8dff8";
		});
		btn.addEventListener("mouseleave", () => {
			btn.style.background = "transparent";
			btn.style.color = "#7eb8f7";
		});
		btn.addEventListener("click", onClick);
		return btn;
	}

	// ── Floating action bar (fixed bottom-right, structure-agnostic) ───────────
	function buildBar() {
		const bar = document.createElement("div");
		Object.assign(bar.style, {
			position: "fixed",
			right: "16px",
			bottom: "16px",
			display: "flex",
			alignItems: "center",
			gap: "8px",
			padding: "6px",
			background: "rgba(15,23,42,0.92)",
			border: "1px solid #3d5a80",
			borderRadius: "8px",
			boxShadow: "0 6px 20px rgba(0,0,0,0.45)",
			zIndex: "99999",
			backdropFilter: "blur(4px)",
			fontFamily: "monospace",
		});

		const label = document.createElement("span");
		label.textContent = "DO DB";
		Object.assign(label.style, {
			color: "#7eb8f7",
			fontSize: "11px",
			letterSpacing: "0.5px",
			padding: "0 4px",
			opacity: "0.8",
		});
		bar.append(label);

		const psqlBtn = makeButton(ICON_PSQL, "psql", () => {
			const d = parseDetails();
			if (!d.host) {
				toast("⚠ No connection details found on this page", true);
				return;
			}
			if (isMasked(d.password)) {
				toast("⚠ Reveal the password first, then click again", true);
				return;
			}
			copyText(buildPsqlCmd(d));
			toast("psql connect command copied!");
		});

		const dumpBtn = makeButton(ICON_DUMP, "pg_dump", () => {
			const d = parseDetails();
			if (!d.host) {
				toast("⚠ No connection details found on this page", true);
				return;
			}
			if (isMasked(d.password)) {
				toast("⚠ Reveal the password first, then click again", true);
				return;
			}
			copyText(buildDumpCmd(d));
			toast("pg_dump command copied!");
		});

		const scpBtn = makeButton(ICON_SCP, "scp", () => {
			const d = parseDetails();
			if (!d.database) {
				toast("⚠ No connection details found on this page", true);
				return;
			}
			copyText(buildScpCmd(d));
			toast("scp command copied!");
		});

		bar.append(psqlBtn, dumpBtn, scpBtn);
		return bar;
	}

	// ── Mount once, reposition if it gets removed (SPA navigations) ────────────
	let mounted = null;
	function mount() {
		if (mounted && document.body.contains(mounted)) return;
		mounted = buildBar();
		document.body.append(mounted);
	}

	const observer = new MutationObserver(mount);
	observer.observe(document.documentElement, {
		childList: true,
		subtree: true,
	});
	mount();
})();
