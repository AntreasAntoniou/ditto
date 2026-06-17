import AppKit
import Carbon.HIToolbox

/// Writes a clip back to the system pasteboard and (optionally) issues a paste
/// into whichever app was frontmost before Ditto opened.
@MainActor
enum Paster {
    /// Place the clip on the general pasteboard.
    static func writeToPasteboard(_ item: ClipItem, store: ClipStore) {
        let pb = NSPasteboard.general
        pb.clearContents()

        switch item.kind {
        case .image:
            if let file = item.payloadFile,
               let image = NSImage(contentsOf: store.storeDirectory.appendingPathComponent(file)) {
                pb.writeObjects([image])
            }
        case .file:
            if let path = item.filePath {
                pb.writeObjects([URL(fileURLWithPath: path) as NSURL])
            }
        default:
            if let rtf = item.rtf {
                pb.setData(rtf, forType: .rtf)
            }
            pb.setString(item.text, forType: .string)
        }
    }

    /// Activate the previously-frontmost app and simulate ⌘V.
    static func paste(into app: NSRunningApplication?) {
        app?.activate(options: [])
        // Small delay so activation completes before the keystroke lands.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            sendCommandV()
        }
    }

    private static func sendCommandV() {
        guard let src = CGEventSource(stateID: .combinedSessionState) else { return }
        let vKey: CGKeyCode = 0x09 // 'v'
        let down = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
