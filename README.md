**Make the Claude desktop app look the way *you* want.**
Add your own wallpaper, frosted-glass panels, new fonts and colours, all from a panel built right into Claude.

Im pretty new to all of this and this is all vibe coded slop xD, ill try make some updates as i go as this is something ive been wanting
for awhile but couldnt find anything online

<img width="1617" height="955" alt="image" src="https://github.com/user-attachments/assets/aa5f77d6-d875-4b26-a4e0-acca242a2ad0" />

---

## ✨ What you can do

| | |
|---|---|
| 🖼️ **Backdrop** | Use any picture as your wallpaper (just drag it in), or pick one of 8 gradients. Darken it, blur it, or turn the colour up or down. |
| 🎭 **Themes** | 8 one-click looks: Glass Night, Aurora, Sunset, Sakura, Ocean, Terminal, Cozy and Playful. |
| 🪟 **Style** | Frosted-glass panels, an accent colour, rounder or squarer message box, slim scrollbars. |
| 🔤 **Fonts** | 10 fonts built in (Inter, Nunito, Poppins, Outfit and more), or any font on your PC. Your code font can be different too. |
| 🧩 **Extras** | Write your own CSS, share themes with friends (copy and paste), move and resize the panel. |

Open the panel with the 🎨 button in Claude's **top-left toolbar** (next to the ← → arrows), or press **Ctrl + Shift + Y**.

---

## 📥 Install (takes about a minute)

> You need the **Claude desktop app for Windows**.

1. **Unzip** `ClaudeStyle.zip` (right-click it, then **Extract All**).
2. Double-click **`Install.bat`**.
   *If Windows shows a blue "protected your PC" box, click **More info**, then **Run anyway**.*
3. Open Claude, click the **menu** (☰, top-left), then **Developer → Enable Main Process Debugger** so it has a tick ✓.

That's it. From now on, **just open Claude normally**. ClaudeStyle starts with Windows and connects by itself within a few seconds. You'll see a little "ClaudeStyle is on" notification.

> 💡 **Step 3 is the "door" ClaudeStyle uses to get into Claude.** If the tick is ever off, ClaudeStyle shows a reminder.

---

## 🎛️ Using the panel

| Tab | What's there |
|---|---|
| **Themes** | One-click looks. Click one and you're done. Changed your mind? Click **Undo**. |
| **Backdrop** | Choose **Image**, **Gradient** or **None**. Drag a picture onto the box to use it. |
| **Style** | Panel colour, see-through amount, glass blur, accent colour, and **Reduce effects**. |
| **Text** | Pick a font. Each one shows a preview in its own style. |
| **More** | Quick CSS, copy or paste themes, where the 🎨 button lives, and reset. |

- **Move the panel:** drag it by its title.
- **Resize the panel:** drag its bottom-right corner.
- **Put it back:** double-click the title (position) or the corner (size).
- **Close the panel:** press **Esc**.

---

## ⏸️ Turning it off

| I want to… | Do this |
|---|---|
| See Claude's normal look for a moment | Flip the switch at the top of the ClaudeStyle panel. |
| Turn ClaudeStyle off completely | Start menu → **ClaudeStyle - Turn off**. It's removed from Claude straight away and won't start with Windows. Your themes are kept. |
| Turn it back on | Start menu → **ClaudeStyle - Turn on** (or click the **ClaudeStyle** shortcut). |
| Remove it for good | Double-click **`Uninstall.bat`**. |

---

## ❓ Questions

**Is it permanent?**
Yes, until you turn it off or uninstall it. Your settings are saved inside Claude, so they stay put.

**What happens when Claude updates?**
Usually nothing. ClaudeStyle doesn't change any of Claude's files, so updates can't break or erase it. If an update changes Claude's layout, a grey patch might come back or the 🎨 button might sit somewhere odd. You can still open the panel with **Ctrl + Shift + Y**, or switch to the floating button under **More**.

**Will it slow Claude down?**
It's built to stay light: it only does its checks when Claude is idle. If things ever feel sluggish, turn on **Style → Reduce effects** to switch off the blur.

**Is it safe?**
ClaudeStyle only changes how Claude *looks*. It doesn't read your chats or send anything anywhere. It uses Claude's own Developer menu to get in, and while that's switched on, other programs on your PC could connect to Claude the same way. Turn ClaudeStyle off (and untick the menu item) if you don't want that.

**Something looks wrong?**
First check that **Developer → Enable Main Process Debugger** is ticked in Claude. Still stuck? ClaudeStyle keeps a log of what it did: press **Win + R**, paste `%LOCALAPPDATA%\ClaudeStyle\log.txt` and press Enter.

---

## 🛠️ For tinkerers

- Put your own CSS in **`theme.css`** inside `%LOCALAPPDATA%\ClaudeStyle\`, or use **More → Quick CSS**. Changes show up instantly.
- To find what to style, open **Developer → Show Dev Tools** in Claude and inspect anything.
- Log file: `%LOCALAPPDATA%\ClaudeStyle\log.txt`

---

*ClaudeStyle is a fan-made project and isn't made by or affiliated with Anthropic.
The bundled fonts are free fonts under the SIL Open Font License (see `FONT-LICENSES.txt`).*

## 🖼️ Tabs Showcase

<img width="3200" height="1800" alt="image" src="https://github.com/user-attachments/assets/d96f7ac1-d485-467d-b074-db937461b217" />
<img width="1456" height="819" alt="image" src="https://github.com/user-attachments/assets/339a5704-f4b6-469c-a401-8e9363511e82" />
<img width="3200" height="1800" alt="image" src="https://github.com/user-attachments/assets/6344d1ce-d622-4ede-bd66-499f5dcfca2e" />
<img width="1456" height="819" alt="image" src="https://github.com/user-attachments/assets/2b130f9f-e528-4446-b60f-45029edd3258" />
<img width="1456" height="819" alt="image" src="https://github.com/user-attachments/assets/d69326ab-f61d-44ac-a0d6-0b0eb4bafd76" />

