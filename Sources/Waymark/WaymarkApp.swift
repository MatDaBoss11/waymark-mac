import AppKit
import ServiceManagement
import SwiftUI
import WaymarkCore

@main
enum WaymarkApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = WaymarkDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class WaymarkDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let defaults = UserDefaults.standard
    private lazy var preferences = Preferences(defaults: defaults)
    private lazy var session = ActivitySession(now: WaymarkTime.now, idleLimit: preferences.idleLimit)
    private lazy var previewDeck = PromptDeck()
    private lazy var monitor = ActivityMonitor { [weak self] in self?.interrupt() }
    private lazy var panel = CardPanel()
    private var settingsWindow: NSWindow?
    private var timer: Timer?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let statusLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let reopenItem = NSMenuItem(title: "Open check-in", action: #selector(reopen), keyEquivalent: "")
    private let quietItem = NSMenuItem(title: "Quiet for an hour", action: #selector(toggleQuiet), keyEquivalent: "")

    private var visible: CheckIn?
    private var tucked: CheckIn?
    private var hideAt: TimeInterval?
    private var intention: NextMove?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenu()
        preferences.didChangeIdle = { [weak self] in
            guard let self else { return }
            self.session.idleLimit = self.preferences.idleLimit
            self.interrupt()
        }
        interrupt()
        poll()

        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        timer.tolerance = 0.15
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        if !defaults.bool(forKey: "hasOpened") {
            defaults.set(true, forKey: "hasOpened")
            showSettings()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    private func poll() {
        let previousStart = session.startedAt
        let snapshot = monitor.snapshot(idleLimit: session.idleLimit, wasPassive: session.pace == .passive)
        let now = WaymarkTime.now
        let showCheckIn = session.sample(
            at: now, idle: snapshot.idle, available: snapshot.available,
            inputCount: snapshot.inputCount, keepAwake: snapshot.keepAwake
        )

        if !snapshot.available || (previousStart != nil && previousStart != session.startedAt) {
            clearCards()
        }

        if showCheckIn {
            let prompt = automaticPrompt(recentScroll: snapshot.recentScroll)
            tucked = nil
            present(CheckIn(prompt: prompt), announce: true)
            return
        }

        if var card = visible, case .timing(let timer, let deadline) = card.stage, now >= deadline {
            card.stage = .finished(timer)
            present(card, focused: panel.isKeyWindow)
        } else if let hideAt, now >= hideAt, let card = visible {
            tuck(card)
        }
        refreshIcon()
    }

    private func automaticPrompt(recentScroll: Bool) -> Prompt {
        let key = recentScroll ? "scrollPromptDeck" : "promptDeck"
        let saved = defaults.dictionary(forKey: key)
        var selection = PromptDeck(
            order: saved?["order"] as? [Int] ?? [], cursor: saved?["cursor"] as? Int ?? 0,
            tone: recentScroll ? .coach : nil
        )
        let prompt = selection.draw()
        defaults.set(["order": selection.order, "cursor": selection.cursor], forKey: key)
        return prompt
    }

    private func interrupt() {
        session.interrupt(at: WaymarkTime.now)
        clearCards()
    }

    private func clearCards() {
        tucked = nil
        intention = nil
        dismiss()
    }

    private func present(_ card: CheckIn, focused: Bool = false, announce: Bool = false) {
        visible = card
        let now = WaymarkTime.now
        switch card.stage {
        case .timing:
            hideAt = nil
        case .reflect:
            hideAt = now + 75
        default:
            hideAt = now + ActivitySession.visibleInterval
        }

        let minutes = Int(max(0, now - (session.startedAt ?? now)) / 60)
        panel.present(
            card, minutes: minutes, intention: card.preview ? nil : intention,
            canSnooze: card.preview || session.canSnooze, focused: focused, announce: announce
        ) { [weak self] action in
            self?.handle(action)
        }
        refreshIcon()
    }

    private func handle(_ action: CardAction) {
        guard var card = visible else { return }
        let now = WaymarkTime.now
        switch action {
        case .stay, .dismiss:
            switch card.stage {
            case .prompt:
                card.stage = .reflect(.finish)
                present(card, focused: true)
            case .reflect:
                tuck(card)
            default:
                if !card.preview { session.acknowledge(at: now) }
                dismiss()
            }

        case .snooze:
            guard card.preview || session.canSnooze else { return }
            card.stage = .reflect(.snooze)
            present(card, focused: true)

        case .confirmDismissal:
            guard case .reflect(let dismissal) = card.stage else { return }
            if !card.preview {
                switch dismissal {
                case .finish: session.acknowledge(at: now)
                case .snooze: guard session.snooze(at: now) else { return }
                }
            }
            dismiss()

        case .refocus:
            card.stage = .refocus
            present(card, focused: true)

        case .back:
            card.stage = .prompt
            present(card, focused: true)

        case .startTimer(let timer):
            if !card.preview { session.acknowledge(at: now) }
            card.stage = .timing(timer, until: now + timer.duration)
            present(card, focused: panel.isKeyWindow)

        case .pick(let move):
            if !card.preview {
                intention = move
                session.acknowledge(at: now)
            }
            dismiss()

        case .nextPreview:
            if card.preview { previewNext() }
        }
    }

    private func tuck(_ card: CheckIn) {
        if !card.preview { tucked = card }
        dismiss()
    }

    private func dismiss() {
        if visible != nil {
            panel.makeFirstResponder(nil)
            panel.orderOut(nil)
            panel.contentView = nil
        }
        visible = nil
        hideAt = nil
        refreshIcon()
    }

    private func configureMenu() {
        let menu = NSMenu()
        menu.delegate = self
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        menu.addItem(.separator())

        reopenItem.target = self
        menu.addItem(reopenItem)
        quietItem.target = self
        menu.addItem(quietItem)

        let previewItem = NSMenuItem(title: "Preview a check-in", action: #selector(previewNext), keyEquivalent: "")
        previewItem.target = self
        menu.addItem(previewItem)
        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(NSMenuItem(title: "Quit Waymark", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        refreshIcon()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let now = WaymarkTime.now
        if let quietUntil = session.quietUntil {
            statusLine.title = "Quiet · \(minutesUntil(quietUntil, from: now)) min left"
        } else if let dueAt = session.dueAt {
            if now > dueAt {
                statusLine.title = "Waiting for your next interaction"
            } else {
                let prefix = session.pace == .passive ? "Low-input session" : "Next check-in"
                statusLine.title = "\(prefix) · \(minutesUntil(dueAt, from: now)) min"
            }
        } else if session.pace == .passive {
            statusLine.title = "Waiting for your next interaction"
        } else {
            statusLine.title = "Waiting for activity"
        }
        quietItem.title = session.quietUntil == nil ? "Quiet for an hour" : "Resume check-ins"
        reopenItem.isHidden = tucked == nil && (visible == nil || visible?.preview == true)
    }

    private func minutesUntil(_ time: TimeInterval, from now: TimeInterval) -> Int {
        max(1, Int(ceil((time - now) / 60)))
    }

    private func refreshIcon() {
        let pending = tucked != nil
        let quiet = session.quietUntil != nil
        let signature = pending ? "Waymark, check-in waiting" : quiet ? "Waymark, quiet" : "Waymark"
        guard let button = statusItem.button, button.toolTip != signature else { return }
        let symbol = pending ? "signpost.right.and.left.fill" : quiet ? "pause.circle" : "signpost.right.fill"
        let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium, scale: .medium)
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: signature)?
            .withSymbolConfiguration(configuration)
        button.toolTip = signature
        button.setAccessibilityLabel(signature)
    }

    @objc private func reopen() {
        guard monitor.available,
              let card = tucked ?? visible,
              !card.preview else { return }
        tucked = nil
        present(card, focused: true)
    }

    @objc private func toggleQuiet() {
        let now = WaymarkTime.now
        if session.quietUntil == nil {
            session.pause(at: now)
        } else {
            session.resume(at: now)
        }
        clearCards()
    }

    @objc private func previewNext() {
        guard monitor.available else { return }
        if let visible, !visible.preview { tucked = CheckIn(prompt: visible.prompt) }
        present(CheckIn(prompt: previewDeck.draw(), preview: true), focused: true)
    }

    @objc private func showSettings() {
        preferences.loginStatus = SMAppService.mainApp.status
        if settingsWindow == nil {
            let host = NSHostingController(rootView: SettingsView(preferences: preferences) { [weak self] in
                self?.previewNext()
            })
            let window = NSWindow(contentViewController: host)
            window.title = "Waymark Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
