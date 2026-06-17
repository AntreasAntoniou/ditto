import AppKit
import SwiftUI

/// A borderless panel pinned to the bottom of the active screen that slides up
/// into view — the signature Paste-style presentation.
final class FloatingPanel: NSPanel {
    /// Visible height of the bar.
    static let barHeight: CGFloat = 380

    var onResignKey: (() -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: FloatingPanel.barHeight),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .mainMenu + 1
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func setContent<Content: View>(_ view: Content) {
        let hosting = NSHostingView(rootView: view)
        hosting.autoresizingMask = [.width, .height]
        contentView = hosting
    }

    /// Slide the bar up from below the screen edge.
    func slideIn() {
        guard let screen = targetScreen() else { return }
        let frame = screen.visibleFrame
        let width = frame.width
        let onScreen = NSRect(x: frame.minX, y: frame.minY, width: width, height: Self.barHeight)
        let offScreen = NSRect(x: frame.minX, y: frame.minY - Self.barHeight, width: width, height: Self.barHeight)

        setFrame(offScreen, display: false)
        alphaValue = 1
        makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrame(onScreen, display: true)
        }
    }

    func slideOut(completion: (() -> Void)? = nil) {
        guard let screen = targetScreen() else { orderOut(nil); completion?(); return }
        let frame = screen.visibleFrame
        let offScreen = NSRect(x: frame.minX, y: frame.minY - Self.barHeight,
                               width: frame.width, height: Self.barHeight)
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().setFrame(offScreen, display: true)
        }, completionHandler: {
            self.orderOut(nil)
            completion?()
        })
    }

    /// The screen containing the mouse, falling back to the main screen.
    private func targetScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
    }

    override func resignKey() {
        super.resignKey()
        onResignKey?()
    }
}
