# ClipboardManager

A lightweight macOS clipboard manager that lives in your menu bar. Tracks your clipboard history, lets you re-paste any previous item, and gets out of your way.

## Features

- 📋 Stores up to 20 recent clipboard entries
- ⌨️ Global keyboard shortcut to open from anywhere
- ⚡ Auto-paste on select (no extra Cmd+V needed)
- 🚀 Launch at login support
- 🔢 Press 1–9 to quickly select items from the menu
- 🔇 Runs silently in the menu bar — no Dock icon

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

On first launch, macOS will ask for **Accessibility access** if Auto-Paste is enabled. Grant it in:

> System Settings → Privacy & Security → Accessibility

## Usage

Click the 📎 icon in the menu bar (or use your configured shortcut) to open the clipboard history. Click any item to copy it back to the clipboard — and optionally auto-paste it into the active app.

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
| Auto-Paste on Select | Automatically pastes the selected item into the active app |
| Launch at Login | Starts ClipboardManager when you log in |
| Clear History | Wipes all stored clipboard entries |

## License

MIT
