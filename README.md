# ClipboardManager

A lightweight macOS clipboard manager that lives in your menu bar. Tracks your clipboard history, lets you pin favorite clippings, and gets out of your way.

## Features

- 📋 Stores up to 20 recent clipboard entries
- 📌 Pin up to 5 favorite items at the top of the menu
- ⌥ Hold **Option (⌥)** while clicking any item to Pin/Unpin
- ⌨️ Global keyboard shortcut to open from anywhere
- 🎯 Auto-focuses back to your previously active textbox upon selection (ready for manual `⌘V` paste)
- 🚀 Launch at login support
- 🔢 Press 1–9 to quickly select items from the menu
- 🔇 Runs silently in the menu bar — no Dock icon
- 🔒 No special permissions required (runs completely local and sandboxed)

## Requirements

- macOS 11.0 (Big Sur) or later
- Apple Silicon (arm64)
- Xcode Command Line Tools (for `swiftc`)

## Installation

### Build from source

```bash
git clone git@github.com:sma6871/clipboard-manager-mac.git
cd clipboard-manager-mac
chmod +x build.sh
./build.sh
```

This produces:
- `ClipboardManager.app` — drag to `/Applications` to install
- `ClipboardManager.dmg` — installer with Applications shortcut

### Permissions

ClipboardManager runs entirely locally and requires **no special macOS permissions** (such as Accessibility or Input Monitoring), keeping your device secure and setup simple.

## Usage

- **Copy/Restore:** Click the 📎 icon in the menu bar (or press `⌘ ⇧ V`) to open the history, and click any item to copy it back to the clipboard. Focus will immediately return to your previously active application, allowing you to paste it manually using `⌘V` (no extra mouse clicks required).
- **Pinning:** Hold the **⌥ Option** key while clicking any item in the menu to pin it to the top. Option-click a pinned item to unpin it. Pinned items are saved in their own permanent section and never count towards the 20-item cap.

### Global Shortcuts

Configurable from the menu under **Global Shortcut**:

| Shortcut | Keys |
|---|---|
| Option + Space | ⌥Space |
| Option + C | ⌥C |
| Command + Shift + V | ⌘⇧V (default) |
| Command + Option + V | ⌘⌥V |

### Settings

| Option | Description |
|---|---|
| Launch at Login | Starts ClipboardManager when you log in |
| Clear History | Wipes all stored recent clipboard entries (keeps pinned items) |

## License

MIT
