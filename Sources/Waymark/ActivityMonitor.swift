import AppKit
import IOKit.pwr_mgt

enum WaymarkTime {
    private static let origin = ContinuousClock.now

    static var now: TimeInterval {
        let elapsed = origin.duration(to: .now).components
        return Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
    }
}

@MainActor
final class ActivityMonitor {
    private enum Gate: Hashable, Sendable {
        case sleep, display, console, lock, screenSaver
    }

    struct Snapshot {
        let available: Bool
        let idle: TimeInterval?
        let inputCount: Int
        let keepAwake: Bool
        let recentScroll: Bool
    }

    private let inputSource: CGEventSourceStateID = .hidSystemState
    private let inputTypes: [CGEventType] = [
        .keyDown, .flagsChanged, .mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown,
        .leftMouseDragged, .rightMouseDragged, .otherMouseDragged
    ]
    private let effortTypes: [CGEventType] = [
        .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown
    ]

    private var blocked: Set<Gate> = []
    private var lastCounts: [UInt32]?
    private let interruption: () -> Void

    init(interruption: @escaping () -> Void) {
        self.interruption = interruption
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.willSleepNotification, NSWorkspace.didWakeNotification, .sleep)
        observe(workspace, NSWorkspace.screensDidSleepNotification, NSWorkspace.screensDidWakeNotification, .display)
        observe(workspace, NSWorkspace.sessionDidResignActiveNotification, NSWorkspace.sessionDidBecomeActiveNotification, .console)
        let distributed = DistributedNotificationCenter.default()
        observe(distributed, .init("com.apple.screenIsLocked"), .init("com.apple.screenIsUnlocked"), .lock)
        observe(distributed, .init("com.apple.screensaver.didstart"), .init("com.apple.screensaver.didstop"), .screenSaver)
    }

    var available: Bool {
        guard blocked.isEmpty,
              !NSScreen.screens.isEmpty,
              let session = CGSessionCopyCurrentDictionary() as? [String: Any] else { return false }
        return session["kCGSSessionOnConsoleKey"] as? Bool == true
            && session["CGSSessionScreenIsLocked"] as? Bool != true
    }

    func snapshot(idleLimit: TimeInterval, wasPassive: Bool) -> Snapshot {
        guard available else {
            lastCounts = nil
            return Snapshot(available: false, idle: nil, inputCount: 0, keepAwake: false, recentScroll: false)
        }

        let hardwareIdle = inputTypes.map { CGEventSource.secondsSinceLastEventType(inputSource, eventType: $0) }
        let scrollAges = [inputSource, .combinedSessionState].map {
            CGEventSource.secondsSinceLastEventType($0, eventType: .scrollWheel)
        }
        let idle = (hardwareIdle + scrollAges).filter { $0.isFinite && $0 >= 0 }.min()
        let counts = effortTypes.map { CGEventSource.counterForEventType(inputSource, eventType: $0) }
        let count = lastCounts.map { previous in
            zip(counts, previous).reduce(0) { total, pair in
                total + Int(min(pair.0 &- pair.1, 12))
            }
        } ?? 0
        lastCounts = counts

        let checkPower = wasPassive || (idle ?? 0) >= idleLimit - 5
        return Snapshot(
            available: true, idle: idle, inputCount: count, keepAwake: checkPower && displayHeldAwake,
            recentScroll: scrollAges.contains { (0...10).contains($0) }
        )
    }

    private var displayHeldAwake: Bool {
        var status: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsStatus(&status) == kIOReturnSuccess,
              let levels = status?.takeRetainedValue() as? [String: NSNumber] else { return false }
        return (levels["PreventUserIdleDisplaySleep"]?.intValue ?? 0) > 0
    }

    private func observe(
        _ center: NotificationCenter, _ entered: Notification.Name, _ exited: Notification.Name, _ gate: Gate
    ) {
        for (name, closes) in [(entered, true), (exited, false)] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    if closes {
                        self.blocked.insert(gate)
                    } else {
                        self.blocked.remove(gate)
                    }
                    self.lastCounts = nil
                    self.interruption()
                }
            }
        }
    }
}
