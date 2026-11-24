# 🎨 ClaudeStyle

**Make the Claude desktop app look the way *you* want.**
Add your own wallpaper, frosted-glass panels, new fonts and colours, all from a panel built right into Claude.

<img width="1444" height="853" alt="image" src="https://github.com/user-attachments/assets/80b31d7b-3d40-4bc3-ad12-ceda768773ca" />


---

## ✨ What you can do

| Feature | What it does |
|---|---|
| 🖼️ **Backdrop** | Use any picture as your wallpaper (just drag it in), or pick one of 8 gradients. Darken it, blur it, or turn the colour up or down. |
| 🎭 **Themes** | 8 one-click looks: Glass Night, Aurora, Sunset, Sakura, Ocean, Terminal, Cozy and Playful. |
| 🪟 **Style** | Frosted-glass panels and message box, dark readable popups (Search, menus), an accent colour, rounder or squarer corners, slim scrollbars. |
| 🔤 **Fonts** | 10 fonts built in (Inter, Nunito, Poppins, Outfit and more), or any font on your PC. Your code font can be different too. |
| 🧩 **Extras** | Write your own CSS, share themes with friends (copy and paste), move and resize the panel. |

Open the panel with the 🎨 button in the message box (next to the **+**), or press **Ctrl + Shift + Y** on any page.

---

## 📥 Install (takes about a minute)

> You need **Windows 10 or 11** and the **Claude desktop app**.

1. Double-click **`Install.bat`**.
   *If Windows shows a blue "protected your PC" box, click **More info**, then **Run anyway**.*
2. **Turn on Developer Mode in Claude.** Click the **menu** (☰, top-left), then **Help → Troubleshooting → Enable Developer Mode**. Claude restarts, and a **Developer** menu appears.
   *Already have a **Developer** menu? Skip this step.*
3. **Turn on the debugger.** Click the **menu** (☰) again, then **Developer → Enable Main Process Debugger** so it has a tick ✓.

That's it. From now on, **just open Claude normally**. ClaudeStyle starts with Windows and connects by itself within a few seconds. You'll see a little "ClaudeStyle is on" notification.

> 💡 **Steps 2 and 3 are the "door" ClaudeStyle uses to get into Claude.** The **Enable Main Process Debugger** option only shows up once Developer Mode is on. If the tick is ever off, ClaudeStyle shows a reminder.

**Updating:** download the new zip and run `Install.bat` again. Your themes and settings are kept.

---

## 🎨 How to open ClaudeStyle

| Where | How |
|---|---|
| **Any page** | Press **Ctrl + Shift + Y**. |
| **In a chat** | Click the 🎨 button in the message box, right next to the **+**. |

Want the button somewhere else? Open the panel, go to **More**, and pick **Sidebar**, **Toolbar**, **Floating** or **Hidden**.

---

## 🎛️ Using the panel

| Tab | What's there |
|---|---|
| **Themes** | One-click looks. Click one and you're done. Changed your mind? Click **Undo**. |
| **Backdrop** | Choose **Image**, **Gradient** or **None**. Drag a picture onto the box to use it. |
| **Style** | Panel colour, see-through amount, glass blur, **Dark popups**, **Smart glass**, **Message box** (background on/off, colour, strength), accent colour, and **Reduce effects**. |
| **Text** | Pick a font. Each one shows a preview in its own style. |
| **More** | Quick CSS, copy or paste themes, where the 🎨 button lives, turn off, debug info, and reset. |

- **Move the panel:** drag it by its title.
- **Resize the panel:** drag its bottom-right corner.
- **Put it back:** double-click the title (position) or the corner (size).
- **Close the panel:** press **Esc**.

---

## ⏸️ Turning it off

| I want to… | Do this |
|---|---|
| See Claude's normal look for a moment | Flip the switch at the top of the ClaudeStyle panel. |
| Turn ClaudeStyle off | Panel → **More → Turn off ClaudeStyle**. It shuts down completely: Claude goes back to normal, the 🎨 button disappears, and it stops starting with Windows. Your themes are kept. |
| Turn it back on | Press **Ctrl + Shift + Y** and click **Turn on** (before Claude restarts), or open the **ClaudeStyle** shortcut on your Desktop or Start menu. |
| Remove it for good | Double-click **`Uninstall.bat`**. |

---

## ❓ Questions

**Is it permanent?**
Yes, until you turn it off (More → Turn off ClaudeStyle) or uninstall it. Your settings are saved inside Claude, so they stay put.

**What happens when Claude updates?**
Usually nothing. ClaudeStyle doesn't change any of Claude's files, so updates can't break or erase it. If an update changes Claude's layout, a grey patch might come back or the 🎨 button might sit somewhere odd. You can still open the panel with **Ctrl + Shift + Y**, or move the button under **More**.

**Will it slow Claude down?**
It's built to stay light: it only does its checks when Claude is idle, pauses while Claude is minimised, keeps your wallpaper at your screen's size, and uses **Smart glass** (one pre-blurred copy of the wallpaper instead of live blur). If things ever feel sluggish, turn on **Style → Reduce effects** to switch off the blur.


**Something looks wrong?**
First check that Developer Mode is on and **Developer → Enable Main Process Debugger** is ticked in Claude. Still stuck? Open the panel, go to **More → Copy debug info**, and paste it into a [new issue](https://github.com/0xDonza/ClaudeStyle-Custom-Addon/issues). It only contains layout details, never your chats.

---

## 🛠️ For tinkerers

- Put your own CSS in **`theme.css`** inside `%LOCALAPPDATA%\ClaudeStyle\`, or use **More → Quick CSS**. Changes show up instantly.
- To find what to style, open **Developer → Show Dev Tools** in Claude and inspect anything.
- Log file: `%LOCALAPPDATA%\ClaudeStyle\log.txt`

---

## 🖼️ Tabs Showcase

<img width="3200" height="1800" alt="image" src="https://github.com/user-attachments/assets/d96f7ac1-d485-467d-b074-db937461b217" />
<img width="1456" height="819" alt="image" src="https://github.com/user-attachments/assets/339a5704-f4b6-469c-a401-8e9363511e82" />
<img width="3200" height="1800" alt="image" src="https://github.com/user-attachments/assets/6344d1ce-d622-4ede-bd66-499f5dcfca2e" />
<img width="1456" height="819" alt="image" src="https://github.com/user-attachments/assets/2b130f9f-e528-4446-b60f-45029edd3258" />
<img width="1456" height="819" alt="image" src="https://github.com/user-attachments/assets/d69326ab-f61d-44ac-a0d6-0b0eb4bafd76" />

---

## ✨ Buy Me A Coffee
Feel free to donate this is a free project of mine and im happy to help!

- btc: bc1qvxalp6cj8xe7pemxepgtnpw9l0mq46m5avgrm7
- eth: 0xe01212d062Db453657E10aa37C8c93726154c1a2
- sol: 2CTYC4YquksKNCRS9Tw8mHVEEJS1XLR1SCWtZtX9T6fg

*Made by **Donza**. ClaudeStyle is a fan-made project and isn't made by or affiliated with Anthropic.
The bundled fonts are free fonts under the SIL Open Font License (see `FONT-LICENSES.txt`).*
