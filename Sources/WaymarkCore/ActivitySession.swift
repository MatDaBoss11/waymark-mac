import Foundation

public struct ActivitySession {
    public enum Pace: Equatable, Sendable {
        case regular, highInput, passive
    }

    public static let firstCheckIn: TimeInterval = 600
    public static let quietInterval: TimeInterval = 3_600
    public static let visibleInterval: TimeInterval = 30

    public private(set) var startedAt: TimeInterval?
    public private(set) var dueAt: TimeInterval?
    public private(set) var quietUntil: TimeInterval?
    public private(set) var snoozesUsed = 0
    public private(set) var pace: Pace = .regular
    public var idleLimit: TimeInterval
    public var canSnooze: Bool { startedAt != nil && snoozesUsed < 2 }

    private var earliestInput: TimeInterval
    private var lastSample: TimeInterval?
    private var lastInput: TimeInterval?
    private var followUpFrom: TimeInterval?
    private var snoozedUntil: TimeInterval?
    private var showedWhilePassive = false
    private var recentPassiveInputs: [TimeInterval] = []
    private var interactionSamples: [(time: TimeInterval, count: Int)] = []

    public init(now: TimeInterval, idleLimit: TimeInterval = 180) {
        earliestInput = now
        self.idleLimit = idleLimit
    }

    public mutating func interrupt(at now: TimeInterval) {
        clearActivity()
        earliestInput = now
        lastSample = nil
    }

    public mutating func pause(at now: TimeInterval) {
        interrupt(at: now)
        quietUntil = now + Self.quietInterval
    }

    public mutating func resume(at now: TimeInterval) {
        interrupt(at: now)
        quietUntil = nil
    }

    public mutating func sample(
        at now: TimeInterval,
        idle: TimeInterval?,
        available: Bool = true,
        inputCount: Int = 0,
        keepAwake: Bool = false
    ) -> Bool {
        if let quietUntil {
            guard now >= quietUntil else { return false }
            resume(at: now)
        }

        guard available, let idle, idle.isFinite, idle >= 0 else {
            interrupt(at: now)
            return false
        }

        if let lastSample, now < lastSample || now - lastSample > 8 {
            interrupt(at: now)
        }
        lastSample = now

        if idle >= idleLimit {
            return samplePassive(at: now, keepAwake: keepAwake)
        }

        let input = now - idle
        guard input >= earliestInput else { return false }

        if pace == .passive && keepAwake {
            recentPassiveInputs.removeAll { $0 <= now - 12 }
            if let lastInput, input > lastInput + 0.12 {
                self.lastInput = input
                showedWhilePassive = false
                recentPassiveInputs.append(now)
            }
            if recentPassiveInputs.count < 3 {
                return samplePassive(at: now, keepAwake: true)
            }
        }
        if let lastInput, input - lastInput >= idleLimit, !(pace == .passive && keepAwake) {
            clearActivity()
        }
        if startedAt == nil { startedAt = input }

        lastInput = max(lastInput ?? input, input)
        showedWhilePassive = false
        recentPassiveInputs.removeAll(keepingCapacity: true)
        interactionSamples.removeAll { $0.time <= now - 60 }
        if inputCount > 0 && idle <= 5 {
            interactionSamples.append((now, min(12, inputCount)))
        }
        pace = interactionSamples.count >= 8 && interactionSamples.reduce(0, { $0 + $1.count }) >= 12
            ? .highInput : .regular
        refreshDeadline()

        guard let dueAt, now > dueAt, input > dueAt, idle <= 5 else { return false }
        acknowledge(at: now)
        return true
    }

    public mutating func acknowledge(at now: TimeInterval) {
        guard startedAt != nil else { return }
        followUpFrom = now
        snoozedUntil = nil
        refreshDeadline()
    }

    @discardableResult
    public mutating func snooze(at now: TimeInterval) -> Bool {
        guard canSnooze else { return false }
        snoozesUsed += 1
        snoozedUntil = now + 300
        refreshDeadline()
        return true
    }

    private mutating func samplePassive(at now: TimeInterval, keepAwake: Bool) -> Bool {
        guard keepAwake, startedAt != nil, lastInput != nil else {
            clearActivity()
            return false
        }

        pace = .passive
        interactionSamples.removeAll(keepingCapacity: true)
        refreshDeadline()
        guard let dueAt, now > dueAt, !showedWhilePassive else { return false }
        showedWhilePassive = true
        acknowledge(at: now)
        return true
    }

    private mutating func refreshDeadline() {
        guard let startedAt else { return }
        let normalDeadline: TimeInterval
        switch (pace, followUpFrom) {
        case (.regular, nil): normalDeadline = startedAt + Self.firstCheckIn
        case (.highInput, nil): normalDeadline = startedAt + 900
        case (.passive, nil): normalDeadline = startedAt + 2_400
        case (.regular, let anchor?): normalDeadline = anchor + 1_200
        case (.highInput, let anchor?): normalDeadline = anchor + 1_800
        case (.passive, let anchor?): normalDeadline = anchor + 2_400
        }

        if pace == .passive, let lastInput {
            dueAt = showedWhilePassive ? nil : max(snoozedUntil ?? normalDeadline, lastInput + 2_400)
        } else {
            dueAt = snoozedUntil ?? normalDeadline
        }
    }

    private mutating func clearActivity() {
        startedAt = nil
        dueAt = nil
        lastInput = nil
        followUpFrom = nil
        snoozedUntil = nil
        showedWhilePassive = false
        snoozesUsed = 0
        pace = .regular
        recentPassiveInputs.removeAll(keepingCapacity: true)
        interactionSamples.removeAll(keepingCapacity: true)
    }
}
