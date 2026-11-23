// main-inject.js — runs inside Claude's main process (via Developer > Enable Main Process Debugger).
// Loads ClaudeStyle (mod.js) into Claude's chat windows now and every time they reload.
// The two placeholders below are filled in by ClaudeStyle.ps1.
(() => {
  const req = typeof require === 'function' ? require
    : (process.mainModule ? process.mainModule.require.bind(process.mainModule) : null);
  if (!req) return 'error: no require';
  const { app, webContents } = req('electron');
  const st = globalThis.__claudeStyle || (globalThis.__claudeStyle = {});
  st.mod = __MOD__;
  st.css = __CSS__;
  st.off = false;
  const code = () => st.mod + '\n;window.__claudeMod && window.__claudeMod.setFileCss(' + JSON.stringify(st.css) + ');';
  const url = wc => { try { return wc.isDestroyed() ? '' : wc.getURL(); } catch (e) { return ''; } };
  const isChat = wc => /^https:\/\/([a-z0-9-]+\.)?claude\.ai\//i.test(url(wc));
  const isPage = wc => /^https?:\/\//i.test(url(wc));
  st.inject = wc => {
    if (st.off) return;
    // Prefer claude.ai windows; if the app shows none, fall back to any web page window.
    const anyChat = webContents.getAllWebContents().some(isChat);
    if (anyChat ? isChat(wc) : isPage(wc)) wc.executeJavaScript(code(), true).catch(() => {});
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
