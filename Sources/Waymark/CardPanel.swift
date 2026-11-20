import SwiftUI
import WaymarkCore

@MainActor
final class CardPanel: NSPanel {
    private let width: CGFloat = 465

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 465, height: 210),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        title = "Waymark check-in"
        isFloatingPanel = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        sharingType = .none
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func present(
        _ card: CheckIn,
        minutes: Int,
        intention: NextMove?,
        canSnooze: Bool,
        focused: Bool,
        announce: Bool,
        action: @escaping (CardAction) -> Void
    ) {
        let point = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main else { return }
        let safeArea = screen.visibleFrame
        let cardWidth = min(width, safeArea.width - 36)
        let host = FirstMouseHost(rootView: CheckInView(
            card: card, minutes: minutes, intention: intention,
            canSnooze: canSnooze, width: cardWidth, act: action
        ))
        let size = host.fittingSize
        if contentView != nil { makeFirstResponder(nil) }
        contentView = host
        setFrame(NSRect(
            x: safeArea.maxX - cardWidth - 18,
            y: safeArea.maxY - size.height - 22,
            width: cardWidth,
            height: size.height
        ), display: true)
        invalidateShadow()

        if focused {
            makeKeyAndOrderFront(nil)
        } else {
            orderFrontRegardless()
        }

        if announce && NSWorkspace.shared.isVoiceOverEnabled {
            NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested, userInfo: [
                .announcement: "Waymark check-in. \(card.prompt.title) Open the Waymark menu to respond.",
                .priority: NSAccessibilityPriorityLevel.medium.rawValue
            ])
        }
    }
}

private final class FirstMouseHost<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
