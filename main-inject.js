// main-inject.js — runs inside Claude's main process (via Developer > Enable Main Process Debugger).
// Loads ClaudeStyle (mod.js) into Claude's chat windows now and every time they reload, and puts the
// palette button into the window's own toolbar (which is a separate part of the app from the chat).
// The placeholders (__MOD__, __CSS__, __DIR__, __STARTUP__) are filled in by ClaudeStyle.ps1.
(() => {
  const req = typeof require === 'function' ? require
    : (process.mainModule ? process.mainModule.require.bind(process.mainModule) : null);
  if (!req) return 'error: no require';
  const { app, webContents } = req('electron');
  const st = globalThis.__claudeStyle || (globalThis.__claudeStyle = {});
  st.mod = __MOD__;
  st.css = __CSS__;
  st.dir = __DIR__;           // ClaudeStyle's folder (where the "off" marker lives)
  st.startup = __STARTUP__;   // the "start with Windows" shortcut
  st.off = false;
  if (!st.btnMode) st.btnMode = 'toolbar';

  // The helper only runs while ClaudeStyle is switched on, so anything it loads clears the page's "off" note.
  const code = () => "try { localStorage.removeItem('claudeStyleDisabled'); } catch (e) {}\n" + st.mod + '\n;window.__claudeMod && window.__claudeMod.setFileCss(' + JSON.stringify(st.css) + ');';
  const url = wc => { try { return wc.isDestroyed() ? '' : wc.getURL(); } catch (e) { return ''; } };
  const isChat = wc => /^https:\/\/([a-z0-9-]+\.)?claude\.ai\//i.test(url(wc));
  const isPage = wc => /^https?:\/\//i.test(url(wc));
  // The window frame is one of the app's own built-in pages (never artifacts, previews or other sites).
  const isFrame = wc => /^(app|file):/i.test(url(wc));
  const run = (wc, js) => { try { if (!wc.isDestroyed()) wc.executeJavaScript(js, true).catch(() => {}); } catch (e) {} };
  const chats = () => webContents.getAllWebContents().filter(isChat);

  // Palette button for the window's toolbar. Built without innerHTML so strict pages accept it.
  // A click is passed on through the console (the main process listens and opens the panel in the chat).
  const FRAME = `(() => {
    if (window.__csShell && window.__csShell.v === 2) { window.__csShell.ensure(); return; }
    if (window.__csShell) { try { window.__csShell.remove(); } catch (e) {} }   // an older copy: replace it
    let tb = null, sb = null, mode = 'toolbar';
    const NAMES = ['plugins', 'scheduled', 'artifacts', 'projects', 'code', 'search'];
    const firstText = el => { const w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT); let t; while ((t = w.nextNode())) { const v = t.nodeValue.trim(); if (v) return v.toLowerCase(); } return String(el.getAttribute('aria-label') || '').trim().toLowerCase(); };
    // "ClaudeStyle" item in the window's own left sidebar, copied from Claude's items (Plugins, Scheduled...)
    function ensureSide() {
      if (sb && sb.isConnected) { const r = sb.getBoundingClientRect(); return r.width > 0 && r.height > 0; }
      let ref = null, best = 99;
      for (const el of document.querySelectorAll('a, button, [role="link"], [role="button"], [role="menuitem"]')) {
        if (el.closest('#claude-style-sb')) continue;
        const i = NAMES.indexOf(firstText(el)); if (i < 0 || i >= best) continue;
        const r = el.getBoundingClientRect();
        if (!r.width || !r.height || r.left > innerWidth * 0.4 || r.width < 90) continue;
        if (el.querySelector('a, button, [role="link"], [role="button"]')) continue;
        ref = el; best = i;
      }
      if (!ref) return false;
      let anchor = ref;
      while (anchor.parentElement && anchor.parentElement.children.length === 1 && !/^(NAV|UL|OL|BODY)$/.test(anchor.parentElement.tagName)) anchor = anchor.parentElement;
      const copy = anchor.cloneNode(true);
      const item = anchor === ref ? copy : (copy.querySelector(ref.tagName.toLowerCase()) || copy);
      [copy].concat(Array.from(copy.querySelectorAll('*'))).forEach(el => ['id', 'href', 'aria-current', 'data-active', 'aria-selected', 'aria-describedby', 'aria-controls'].forEach(a => el.removeAttribute(a)));
      copy.id = 'claude-style-sb';
      item.setAttribute('role', 'button'); item.setAttribute('tabindex', '0'); item.setAttribute('aria-label', 'ClaudeStyle'); item.title = 'ClaudeStyle (Ctrl+Shift+Y)';
      const w = document.createTreeWalker(item, NodeFilter.SHOW_TEXT); let t, named = false;
      while ((t = w.nextNode())) { const v = t.nodeValue.trim(); if (!v) continue; if (!named) { t.nodeValue = t.nodeValue.replace(v, 'ClaudeStyle'); named = true; } else t.nodeValue = ''; }
      const old = item.querySelector('svg'), rs = ref.querySelector('svg');
      if (old) { const n = icon(rs ? Math.round(rs.getBoundingClientRect().width) || 18 : 18); if (old.getAttribute('class')) n.setAttribute('class', old.getAttribute('class')); old.replaceWith(n); }
      const go = e => { e.preventDefault(); e.stopPropagation(); console.log('__claudestyle:toggle'); };
      item.addEventListener('click', go, true);
      item.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') go(e); }, true);
      anchor.after(copy); sb = copy;
      console.log('__claudestyle:frame-ok');
      return true;
    }
    const NS = 'http://www.w3.org/2000/svg';
    function icon(size) {
      const s = document.createElementNS(NS, 'svg');
      [['width', size], ['height', size], ['viewBox', '0 0 24 24'], ['fill', 'none'], ['stroke', 'currentColor'], ['stroke-width', '1.8'], ['stroke-linecap', 'round'], ['stroke-linejoin', 'round']].forEach(a => s.setAttribute(a[0], a[1]));
      const p = document.createElementNS(NS, 'path');
      p.setAttribute('d', 'M12 3a9 9 0 1 0 0 18c1.1 0 1.8-.8 1.8-1.8 0-.5-.2-.9-.5-1.2-.3-.3-.5-.7-.5-1.2 0-1 .8-1.8 1.8-1.8H16a5 5 0 0 0 5-5c0-3.9-4-7-9-7Z');
      s.appendChild(p);
      [[7.5, 10.5], [10.5, 7], [15, 7.5], [17, 11]].forEach(c => { const d = document.createElementNS(NS, 'circle'); d.setAttribute('cx', c[0]); d.setAttribute('cy', c[1]); d.setAttribute('r', '1.2'); d.setAttribute('fill', 'currentColor'); s.appendChild(d); });
      return s;
    }
    function buttons() {
      const out = [];
      for (const b of document.querySelectorAll('button, [role="button"]')) {
        if (b === tb) continue;
        const r = b.getBoundingClientRect();
        if (r.top >= 0 && r.top < 72 && r.left < 600 && r.width >= 16 && r.width <= 64 && r.height >= 16 && r.height <= 64 && b.querySelector('svg')) out.push(b);
      }
      return out.sort((a, b) => a.getBoundingClientRect().left - b.getBoundingClientRect().left);
    }
    function ensure() {
      if (mode !== 'sidebar-frame' && sb && sb.isConnected) sb.remove();
      if (mode === 'sidebar-frame' && ensureSide()) { if (tb && tb.isConnected) tb.remove(); return; }
      if (mode !== 'toolbar' && mode !== 'sidebar-frame') { if (tb && tb.isConnected) tb.remove(); return; }
      if (tb && tb.isConnected) return;
      const btns = buttons();
      const lab = b => String(b.getAttribute('aria-label') || b.title || '').toLowerCase();
      const after = btns.find(b => /forward/.test(lab(b))) || btns.find(b => /back/.test(lab(b)));
      if (!after) return;                       // only ever placed right next to the back/forward arrows
      const look = btns.find(b => !b.disabled && b.getAttribute('aria-disabled') !== 'true' && b !== after) || after;
      if (!tb) {
        tb = document.createElement('button');
        tb.type = 'button'; tb.id = 'claude-style-tb';
        tb.setAttribute('aria-label', 'ClaudeStyle'); tb.title = 'ClaudeStyle (Ctrl+Shift+Y)';
        tb.addEventListener('click', e => { e.preventDefault(); e.stopPropagation(); console.log('__claudestyle:toggle'); });
      }
      tb.className = look.className;
      const ref = look.querySelector('svg'), w = ref ? Math.round(ref.getBoundingClientRect().width) : 0;
      while (tb.firstChild) tb.firstChild.remove();
      tb.appendChild(icon(w || 18));
      tb.style.setProperty('-webkit-app-region', 'no-drag');
      let anchor = after;
      while (anchor.parentElement && anchor.parentElement.children.length === 1 && anchor.parentElement !== document.body) anchor = anchor.parentElement;
      anchor.after(tb);
      console.log('__claudestyle:frame-ok');
    }
    const iv = setInterval(ensure, 1500);
    window.__csShell = { v: 2, ensure, mode(m) { mode = m; ensure(); }, remove() { clearInterval(iv); if (tb) tb.remove(); if (sb) sb.remove(); delete window.__csShell; } };
    ensure();
  })()`;

  // Turning ClaudeStyle off or on from its panel: stop or restart the helper and the Windows startup entry.
  const path = req('path'), fs = req('fs');
  const offFile = () => path.join(st.dir, 'off.flag');
  function shutdown() {
    st.off = true;
    try { fs.writeFileSync(offFile(), 'ClaudeStyle was turned off from its panel. Open the ClaudeStyle shortcut to turn it back on.'); } catch (e) {}
    try { fs.unlinkSync(st.startup); } catch (e) {}
    webContents.getAllWebContents().filter(isFrame).forEach(w => run(w, 'window.__csShell && window.__csShell.remove()'));
  }
  function startup() {
    st.off = false;
    if (!fs.existsSync(offFile())) return;
    try {
      const ps = path.join(process.env.SystemRoot || 'C:\\Windows', 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe');
      const child = req('child_process').spawn(ps, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', path.join(st.dir, 'ClaudeStyle.ps1'), '-On', '-Quiet'],
        { detached: true, stdio: 'ignore', windowsHide: true });
      child.on('error', () => {});   // never let a failed start crash Claude
      child.unref();
    } catch (e) {}
  }

  // Messages from the pages (sent with console.log, since the page has no other way to reach us).
  st.onMessage = (wc, msg) => {
    if (typeof msg !== 'string' || msg.indexOf('__claudestyle:') !== 0) return;
    if (msg === '__claudestyle:shutdown') return shutdown();
    if (msg === '__claudestyle:startup') return startup();
    if (st.off) return;
    if (msg === '__claudestyle:toggle') chats().forEach(w => run(w, 'window.__claudeMod && (window.__claudeMod.toggle || window.__claudeMod.open)()'));
    else if (msg === '__claudestyle:frame-ok') chats().forEach(w => run(w, 'window.__claudeMod && window.__claudeMod.shellButton && window.__claudeMod.shellButton(true)'));
    else if (msg.indexOf('__claudestyle:open:') === 0) {
      // links from the panel (only ClaudeStyle's own GitHub pages) open in the normal web browser
      const link = msg.slice(19);
      if (/^https:\/\/github\.com\/0xDonza\/ClaudeStyle-Custom-Addon(\/[\w\-./%]*)?$/.test(link)) {
        try { req('electron').shell.openExternal(link); run(wc, 'window.__claudeMod && window.__claudeMod.linkOpened && window.__claudeMod.linkOpened()'); } catch (e) {}
      }
    }
    else if (msg.indexOf('__claudestyle:btn:') === 0) {
      st.btnMode = msg.slice(18);
      webContents.getAllWebContents().filter(isFrame).forEach(w => run(w, 'window.__csShell && window.__csShell.mode(' + JSON.stringify(st.btnMode) + ')'));
    }
  };
  // Newest ClaudeStyle release on GitHub (read-only; nothing is downloaded). Checked at most once a day.
  const tellUpdate = wc => { if (st.latest) run(wc, 'window.__claudeMod && window.__claudeMod.updateInfo && window.__claudeMod.updateInfo(' + JSON.stringify(st.latest) + ')'); };
  function checkUpdate() {
    const file = path.join(st.dir, 'update.json');
    let cache = null;
    try { cache = JSON.parse(fs.readFileSync(file, 'utf8')); } catch (e) {}
    if (cache && cache.tag) st.latest = { tag: cache.tag, url: cache.url };
    if (cache && Date.now() - (cache.checked || 0) < 24 * 3600 * 1000) { chats().forEach(tellUpdate); return; }
    if (st.checking) return;
    st.checking = true;
    try {
      const r = req('https').get('https://api.github.com/repos/0xDonza/ClaudeStyle-Custom-Addon/releases/latest',
        { headers: { 'User-Agent': 'ClaudeStyle', 'Accept': 'application/vnd.github+json' }, timeout: 8000 }, res => {
          let body = '';
          res.on('data', d => { if (body.length < 200000) body += d; });
          res.on('end', () => {
            st.checking = false;
            try {
              const j = JSON.parse(body);
              if (res.statusCode === 200 && j.tag_name && j.html_url) st.latest = { tag: String(j.tag_name).slice(0, 40), url: String(j.html_url) };
              fs.writeFileSync(file, JSON.stringify({ checked: Date.now(), tag: st.latest && st.latest.tag, url: st.latest && st.latest.url }));
            } catch (e) {}
            chats().forEach(tellUpdate);
          });
        });
      r.on('timeout', () => r.destroy());
      r.on('error', () => { st.checking = false; });
    } catch (e) { st.checking = false; }
  }
  st.listened = st.listened || new WeakSet();
  const listen = wc => {
    if (st.listened.has(wc)) return;
    st.listened.add(wc);
    // Newer Electron passes one event object; older versions pass (event, level, message, ...).
    wc.on('console-message', (e, level, message) => st.onMessage(wc, e && typeof e.message === 'string' ? e.message : message));
  };

  st.inject = wc => {
    if (st.off) return;
    listen(wc);
    // Prefer claude.ai windows; if the app shows none, fall back to any web page window.
    const anyChat = webContents.getAllWebContents().some(isChat);
    if (anyChat ? isChat(wc) : isPage(wc)) { run(wc, code()); setTimeout(() => { tellUpdate(wc); checkUpdate(); }, 4000); }
    else if (anyChat && isFrame(wc)) run(wc, FRAME + ';window.__csShell && window.__csShell.mode(' + JSON.stringify(st.btnMode) + ')');
  };
  if (!st.hooked) {
    st.hooked = true;
    const hook = wc => wc.on('dom-ready', () => st.inject(wc));
    webContents.getAllWebContents().forEach(hook);
    app.on('web-contents-created', (_e, wc) => hook(wc));
  }
  const all = webContents.getAllWebContents();
  all.forEach(wc => st.inject(wc));
  return 'ok: ' + all.map(url).join(' | ');
})()
