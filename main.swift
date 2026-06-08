import Cocoa
import Carbon

enum ShortcutPreset: String, CaseIterable {
    case optionSpace = "Option + Space"
    case optionC = "Option + C"
    case cmdShiftV = "Command + Shift + V"
    case cmdOptionV = "Command + Option + V"
    
    var keyCode: UInt32 {
        switch self {
        case .optionSpace: return 49
        case .optionC: return 8
        case .cmdShiftV: return 9
        case .cmdOptionV: return 9
        }
    }
    
    var modifiers: UInt32 {
        switch self {
        case .optionSpace: return UInt32(optionKey)
        case .optionC: return UInt32(optionKey)
        case .cmdShiftV: return UInt32(cmdKey | shiftKey)
        case .cmdOptionV: return UInt32(cmdKey | optionKey)
        }
    }
    
    var displayString: String {
        switch self {
        case .optionSpace: return "⌥Space"
        case .optionC: return "⌥C"
        case .cmdShiftV: return "⌘⇧V"
        case .cmdOptionV: return "⌘⌥V"
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    var clipboardHistory: [String] = []
    let maxHistoryItems = 20
    var lastChangeCount = 0
    
    var activeShortcut: ShortcutPreset = .cmdShiftV
    var hotKeyRef: EventHotKeyRef?
    var eventHandlerRef: EventHandlerRef?
    
    var previouslyActiveApp: NSRunningApplication?
    
    var autoPasteEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "autoPasteEnabled") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "autoPasteEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "autoPasteEnabled")
        }
    }
    
    var launchAtLoginEnabled: Bool {
        get {
            let fileManager = FileManager.default
            let launchFolder = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
            let plistURL = launchFolder.appendingPathComponent("com.user.ClipboardManager.plist")
            return fileManager.fileExists(atPath: plistURL.path)
        }
        set {
            let fileManager = FileManager.default
            let launchFolder = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
            let plistURL = launchFolder.appendingPathComponent("com.user.ClipboardManager.plist")
            
            if newValue {
                try? fileManager.createDirectory(at: launchFolder, withIntermediateDirectories: true, attributes: nil)
                
                guard let execPath = Bundle.main.executablePath else { return }
                
                let plistDict: [String: Any] = [
                    "Label": "com.user.ClipboardManager",
                    "ProgramArguments": [execPath],
                    "RunAtLoad": true
                ]
                
                let plistData = try? PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
                try? plistData?.write(to: plistURL)
            } else {
                try? fileManager.removeItem(at: plistURL)
            }
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a background/agent app (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Setup status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            // Native paperclip icon
            if let image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "Clipboard Manager") {
                button.image = image
            } else {
                button.title = "📋"
            }
        }
        
        // Load data
        loadHistory()
        loadShortcutPreference()
        
        // Initialize menu
        setupMenu()
        
        // Initialize global hotkey handler
        setupEventHandler()
        updateShortcut(activeShortcut)
        
        // Start clipboard polling (0.5s interval)
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func loadHistory() {
        if let saved = UserDefaults.standard.stringArray(forKey: "clipboardHistory") {
            clipboardHistory = saved
        }
    }
    
    func saveHistory() {
        UserDefaults.standard.set(clipboardHistory, forKey: "clipboardHistory")
    }
    
    func loadShortcutPreference() {
        if let savedRaw = UserDefaults.standard.string(forKey: "selectedShortcut"),
           let preset = ShortcutPreset(rawValue: savedRaw) {
            activeShortcut = preset
        }
    }
    
    func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self
        
        // Header
        let header = NSMenuItem(title: "Clipboard Manager", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())
        
        // Clipboard History Items
        if clipboardHistory.isEmpty {
            let emptyItem = NSMenuItem(title: "No copied text", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for (index, item) in clipboardHistory.enumerated() {
                // Prettify by replacing newlines with spaces for single-line menu items
                let singleLineText = item.replacingOccurrences(of: "\n", with: " ")
                
                // Truncate display title
                let displayTitle = singleLineText.count > 45 ? String(singleLineText.prefix(42)) + "..." : singleLineText
                
                // Shortcut key equivalent (1 to 9 for keyboard navigation)
                var keyEq = ""
                if index < 9 {
                    keyEq = "\(index + 1)"
                }
                
                let menuItem = NSMenuItem(title: displayTitle, action: #selector(copyItem(_:)), keyEquivalent: keyEq)
                menuItem.representedObject = item
                menuItem.target = self
                menuItem.toolTip = item // Hover to see full multiline content
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Global Shortcuts submenu
        let shortcutsMenu = NSMenu()
        for preset in ShortcutPreset.allCases {
            let item = NSMenuItem(title: "\(preset.rawValue) (\(preset.displayString))", action: #selector(selectShortcutPreset(_:)), keyEquivalent: "")
            item.representedObject = preset.rawValue
            item.target = self
            if preset == activeShortcut {
                item.state = .on
            }
            shortcutsMenu.addItem(item)
        }
        
        let shortcutParent = NSMenuItem(title: "Global Shortcut", action: nil, keyEquivalent: "")
        shortcutParent.submenu = shortcutsMenu
        menu.addItem(shortcutParent)
        
        // Launch at Login checkbox
        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = launchAtLoginEnabled ? .on : .off
        menu.addItem(launchItem)
        
        // Auto-Paste on Select checkbox
        let autoPasteItem = NSMenuItem(title: "Auto-Paste on Select", action: #selector(toggleAutoPaste(_:)), keyEquivalent: "")
        autoPasteItem.target = self
        autoPasteItem.state = autoPasteEnabled ? .on : .off
        menu.addItem(autoPasteItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Actions
        let clearItem = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        launchAtLoginEnabled.toggle()
        setupMenu()
    }
    
    @objc func toggleAutoPaste(_ sender: NSMenuItem) {
        autoPasteEnabled.toggle()
        
        if autoPasteEnabled {
            let isTrusted = AXIsProcessTrusted()
            if !isTrusted {
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                AXIsProcessTrustedWithOptions(options)
            }
        }
        
        setupMenu()
    }
    
    @objc func copyItem(_ sender: NSMenuItem) {
        guard let text = sender.representedObject as? String else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Update change count so we ignore our own write
        lastChangeCount = pasteboard.changeCount
        
        // Restore focus to previously active app
        if let prevApp = previouslyActiveApp {
            prevApp.activate(options: .activateIgnoringOtherApps)
            
            // Auto-paste if enabled
            if autoPasteEnabled {
                if AXIsProcessTrusted() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self.simulatePaste()
                    }
                } else {
                    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                    AXIsProcessTrustedWithOptions(options)
                }
            }
            
            previouslyActiveApp = nil
        }
    }
    
    func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Command + V keydown (0x09 is kVK_ANSI_V)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else { return }
        keyDown.flags = .maskCommand
        
        // Command + V keyup
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else { return }
        keyUp.flags = .maskCommand
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
    
    @objc func clearHistory() {
        clipboardHistory.removeAll()
        saveHistory()
        setupMenu()
    }
    
    @objc func selectShortcutPreset(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let preset = ShortcutPreset(rawValue: rawValue) else { return }
        
        updateShortcut(preset)
        setupMenu()
    }
    
    func captureActiveApp() {
        if let currentApp = NSWorkspace.shared.frontmostApplication,
           currentApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            previouslyActiveApp = currentApp
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        captureActiveApp()
    }
    
    func toggleMenu() {
        captureActiveApp()
        NSApplication.shared.activate(ignoringOtherApps: true)
        setupMenu() // Ensure current items are loaded
        
        let mouseLocation = NSEvent.mouseLocation
        if let menu = statusItem?.menu {
            menu.popUp(positioning: nil, at: mouseLocation, in: nil)
        }
    }
    
    func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        if let newString = pasteboard.string(forType: .string) {
            let trimmed = newString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            
            // Avoid duplicate items, move existing to top
            if let index = clipboardHistory.firstIndex(of: trimmed) {
                clipboardHistory.remove(at: index)
            }
            
            clipboardHistory.insert(trimmed, at: 0)
            if clipboardHistory.count > maxHistoryItems {
                clipboardHistory.removeLast()
            }
            
            saveHistory()
            setupMenu()
        }
    }
    
    func setupEventHandler() {
        let hotKeyHandler: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            DispatchQueue.main.async {
                if let delegate = NSApplication.shared.delegate as? AppDelegate {
                    delegate.toggleMenu()
                }
            }
            return noErr
        }
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyHandler,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
        
        if status != noErr {
            print("Failed to install global hotkey handler: \(status)")
        }
    }
    
    func updateShortcut(_ preset: ShortcutPreset) {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        
        activeShortcut = preset
        UserDefaults.standard.set(preset.rawValue, forKey: "selectedShortcut")
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x636c7031), id: 1)
        let status = RegisterEventHotKey(
            preset.keyCode,
            preset.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            print("Failed to register hotkey for \(preset.rawValue): \(status)")
        }
    }
}

// Entrypoint
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
