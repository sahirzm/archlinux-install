// ==UserScript==
// @name         DigitalOcean DB Quick Commands
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Add psql connect and pg_dump copy buttons to DO database connection details
// @author       You
// @match        https://cloud.digitalocean.com/databases*
// @updateURL    https://raw.githubusercontent.com/sahirzm/archlinux-install/main/tampermonkey-scripts/do-db-commands.user.js
// @downloadURL  https://raw.githubusercontent.com/sahirzm/archlinux-install/main/tampermonkey-scripts/do-db-commands.user.js
// @grant        GM_setClipboard
// ==/UserScript==

(function () {
    'use strict';

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

    // ── Parse connection details from panel ────────────────────────────────────
    function parseDetails(panel) {
        const details = {};
        const lines = panel.querySelectorAll('[class*="ParametersCode__Line"]');
        lines.forEach(line => {
            const key = line.querySelector('strong')?.textContent?.trim();
            if (!key) return;
            const clone = line.cloneNode(true);
            clone.querySelectorAll('strong, button').forEach(el => el.remove());
            const value = clone.textContent.replace(/^\s*=\s*/, '').trim();
            details[key] = value;
        });
        return details;
    }

    function isMasked(value) {
        return /^\*+$/.test(value);
    }

    // ── Command builders ───────────────────────────────────────────────────────
    function buildPsqlCmd(d) {
        let cmd = `PGPASSWORD=${d.password} psql -U ${d.username} -h ${d.host} -p ${d.port} -d ${d.database}`;
        if (d.sslmode) cmd += ` --set=sslmode=${d.sslmode}`;
        return cmd;
    }

    function buildDumpCmd(d) {
        const now = new Date();
        const pad = n => String(n).padStart(2, '0');
        const ts = `${now.getUTCFullYear()}${pad(now.getUTCMonth() + 1)}${pad(now.getUTCDate())}_${pad(now.getUTCHours())}${pad(now.getUTCMinutes())}`;
        return `PGPASSWORD=${d.password} pg_dump -U ${d.username} -h ${d.host} -p ${d.port} -Fc --no-owner ${d.database} > db_dump_${ts}.sql`;
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
        const el = document.createElement('div');
        el.textContent = msg;
        Object.assign(el.style, {
            position: 'fixed',
            bottom: '24px',
            right: '24px',
            background: isWarn ? '#7c3a1e' : '#1a3a5c',
            color: '#fff',
            padding: '10px 16px',
            borderRadius: '6px',
            fontSize: '13px',
            zIndex: '99999',
            boxShadow: '0 4px 14px rgba(0,0,0,0.4)',
            transition: 'opacity 0.3s',
            fontFamily: 'monospace',
        });
        document.body.appendChild(el);
        setTimeout(() => {
            el.style.opacity = '0';
            setTimeout(() => el.remove(), 300);
        }, 2500);
    }

    // ── Button factory ─────────────────────────────────────────────────────────
    function makeButton(icon, label, onClick) {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.innerHTML = `${icon} <span>${label}</span>`;
        Object.assign(btn.style, {
            display: 'inline-flex',
            alignItems: 'center',
            gap: '5px',
            background: 'transparent',
            border: '1px solid #3d5a80',
            borderRadius: '5px',
            color: '#7eb8f7',
            cursor: 'pointer',
            fontSize: '12px',
            padding: '4px 10px',
            transition: 'background 0.15s, color 0.15s',
        });
        btn.addEventListener('mouseenter', () => {
            btn.style.background = '#1a3a5c';
            btn.style.color = '#c8dff8';
        });
        btn.addEventListener('mouseleave', () => {
            btn.style.background = 'transparent';
            btn.style.color = '#7eb8f7';
        });
        btn.addEventListener('click', onClick);
        return btn;
    }

    // ── Inject buttons into panel ──────────────────────────────────────────────
    function inject(panel) {
        if (panel.dataset.doQuickCmds) return;
        const pre = panel.querySelector('pre');
        if (!pre) return;
        panel.dataset.doQuickCmds = '1';

        const bar = document.createElement('div');
        Object.assign(bar.style, {
            display: 'flex',
            gap: '8px',
            marginTop: '8px',
            padding: '0 2px',
        });

        const psqlBtn = makeButton(ICON_PSQL, 'psql connect', () => {
            const d = parseDetails(panel);
            if (isMasked(d.password)) {
                toast('⚠ Reveal the password first, then click again', true);
                return;
            }
            copyText(buildPsqlCmd(d));
            toast('psql connect command copied!');
        });

        const dumpBtn = makeButton(ICON_DUMP, 'pg_dump', () => {
            const d = parseDetails(panel);
            if (isMasked(d.password)) {
                toast('⚠ Reveal the password first, then click again', true);
                return;
            }
            copyText(buildDumpCmd(d));
            toast('pg_dump command copied!');
        });

        bar.appendChild(psqlBtn);
        bar.appendChild(dumpBtn);
        pre.insertAdjacentElement('afterend', bar);
    }

    // ── Watch for dynamic content ──────────────────────────────────────────────
    function tryInject() {
        const panel = document.getElementById('connection-details-panel-1');
        if (panel?.querySelector('pre')) inject(panel);
    }

    const observer = new MutationObserver(tryInject);
    observer.observe(document.body, { childList: true, subtree: true });
    tryInject();
})();
