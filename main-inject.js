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
    if (window.__csShell) { window.__csShell.ensure(); return; }
    let tb = null, mode = 'toolbar';
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
      if (mode !== 'toolbar') { if (tb && tb.isConnected) tb.remove(); return; }
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
    window.__csShell = { ensure, mode(m) { mode = m; ensure(); }, remove() { clearInterval(iv); if (tb) tb.remove(); delete window.__csShell; } };
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
    else if (msg.indexOf('__claudestyle:btn:') === 0) {
      st.btnMode = msg.slice(18);
      webContents.getAllWebContents().filter(isFrame).forEach(w => run(w, 'window.__csShell && window.__csShell.mode(' + JSON.stringify(st.btnMode) + ')'));
    }
  };
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
    if (anyChat ? isChat(wc) : isPage(wc)) run(wc, code());
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
