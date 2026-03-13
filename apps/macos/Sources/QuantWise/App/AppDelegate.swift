import AppKit
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_: Notification) {
        // Hide from Dock — menubar-only app
        NSApp.setActivationPolicy(.accessory)
        registerGlobalHotKey()
    }

    // MARK: - Global Hotkey (Cmd+Shift+Q)

    private func registerGlobalHotKey() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Install Carbon event handler
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyCallback,
            1,
            &eventSpec,
            nil,
            nil
        )
        guard status == noErr else { return }

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x5157_5753) // "QWWS"
        hotKeyID.id = 1

        RegisterEventHotKey(
            UInt32(kVK_ANSI_Q),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}

/// Carbon event handler — toggles the app (shows/hides the MenuBarExtra popover)
private func hotKeyCallback(
    _: EventHandlerCallRef?,
    _: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    DispatchQueue.main.async {
        if NSApp.isActive {
            NSApp.hide(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    return noErr
}
