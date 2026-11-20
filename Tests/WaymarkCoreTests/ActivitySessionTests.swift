import Foundation
import Testing
@testable import WaymarkCore

struct ActivitySessionTests {
    @Test func thresholdRequiresInputAfterTenFullMinutes() {
        var session = ActivitySession(now: 0)
        for second in stride(from: 0, through: 600, by: 2) {
            #expect(session.sample(at: Double(second), idle: 0) == false)
        }
        #expect(session.sample(at: 602, idle: 2) == false)
        #expect(session.sample(at: 604, idle: 0) == true)
        #expect(session.startedAt == 0)
        #expect(session.dueAt == 1_804)
    }

    @Test func fixedFollowUpCoversAnIgnoredCard() {
        var session = ActivitySession(now: 0)
        var reminders: [Int] = []
        for second in stride(from: 0, through: 1_806, by: 2) {
            if session.sample(at: Double(second), idle: 0) { reminders.append(second) }
        }
        #expect(reminders == [602, 1_804])
    }

    @Test func noSessionCanStartFromInputBeforeLaunch() {
        var session = ActivitySession(now: 100)
        #expect(session.sample(at: 100, idle: 0.5) == false)
        #expect(session.startedAt == nil)
        #expect(session.sample(at: 102, idle: 1) == false)
        #expect(session.startedAt == 101)
    }

    @Test func idleBreakCanBeDetectedBetweenSamples() {
        var session = ActivitySession(now: 0, idleLimit: 90)
        for second in stride(from: 0, through: 88, by: 2) {
            #expect(session.sample(at: Double(second), idle: Double(second)) == false)
        }
        #expect(session.sample(at: 90, idle: 0) == false)
        #expect(session.startedAt == 90)
        #expect(session.dueAt == 690)
    }

    @Test func heavyInputDelaysCheckInsWithoutClassifyingScrollsAsWork() {
        var session = ActivitySession(now: 0)
        var reminders: [Int] = []
        for second in stride(from: 0, through: 2_704, by: 2) {
            if session.sample(at: Double(second), idle: 0, inputCount: 3) { reminders.append(second) }
        }
        #expect(reminders == [902, 2_704])
        #expect(session.pace == .highInput)
    }

    @Test func inputFreeViewingCanShowOnceAtFortyMinutes() {
        var session = ActivitySession(now: 0)
        var reminders: [Int] = []
        for second in stride(from: 0, through: 5_000, by: 2) {
            if session.sample(at: Double(second), idle: Double(second), keepAwake: true) {
                reminders.append(second)
            }
        }
        #expect(reminders == [2_402])
        #expect(session.pace == .passive)
        #expect(session.dueAt == nil)
    }

    @Test func isolatedVideoControlsKeepTheLongerViewingInterval() {
        var session = ActivitySession(now: 0)
        for second in stride(from: 0, through: 900, by: 2) {
            #expect(session.sample(at: Double(second), idle: Double(second), keepAwake: true) == false)
        }
        #expect(session.sample(at: 902, idle: 0, inputCount: 1, keepAwake: true) == false)
        #expect(session.pace == .passive)
        #expect(session.dueAt == 3_302)
        #expect(session.sample(at: 904, idle: 0, keepAwake: true) == false)
        #expect(session.sample(at: 906, idle: 0, keepAwake: true) == true)
        #expect(session.pace == .regular)
    }

    @Test func idleWithoutPowerEvidenceEndsSession() {
        var session = ActivitySession(now: 0)
        #expect(session.sample(at: 0, idle: 0) == false)
        for second in stride(from: 2, through: 180, by: 2) {
            #expect(session.sample(at: Double(second), idle: Double(second)) == false)
        }
        #expect(session.startedAt == nil)
        #expect(session.sample(at: 182, idle: 182, keepAwake: true) == false)
        #expect(session.startedAt == nil)
    }

    @Test func losingPowerEvidenceDuringPassiveViewingEndsSession() {
        var session = ActivitySession(now: 0)
        for second in stride(from: 0, through: 240, by: 2) {
            #expect(session.sample(at: Double(second), idle: Double(second), keepAwake: true) == false)
        }
        #expect(session.pace == .passive)
        #expect(session.sample(at: 242, idle: 242, keepAwake: false) == false)
        #expect(session.startedAt == nil)
    }

    @Test func snoozesAreLimitedAndResetWithSession() {
        var session = ActivitySession(now: 0)
        for second in stride(from: 0, through: 602, by: 2) {
            _ = session.sample(at: Double(second), idle: 0)
        }
        #expect(session.snooze(at: 604) == true)
        #expect(session.dueAt == 904)
        for second in stride(from: 604, through: 906, by: 2) {
            #expect(session.sample(at: Double(second), idle: 0) == (second == 906))
        }
        #expect(session.snooze(at: 908) == true)
        #expect(!session.canSnooze)
        #expect(session.snooze(at: 1_210) == false)
        session.interrupt(at: 1_212)
        #expect(session.sample(at: 1_214, idle: 0) == false)
        #expect(session.canSnooze)
        #expect(session.snoozesUsed == 0)
    }

    @Test func quietAndLifecycleTransitionsNeedFreshInput() {
        var session = ActivitySession(now: 0)
        #expect(session.sample(at: 0, idle: 0) == false)
        session.pause(at: 10)
        #expect(session.sample(at: 3_609, idle: 0, keepAwake: true) == false)
        #expect(session.sample(at: 3_610, idle: 1) == false)
        #expect(session.startedAt == nil)
        #expect(session.sample(at: 3_612, idle: 0) == false)
        #expect(session.startedAt == 3_612)
        #expect(session.sample(at: 3_614, idle: 0, available: false) == false)
        #expect(session.startedAt == nil)
        #expect(session.sample(at: 3_616, idle: 0) == false)
        #expect(session.sample(at: 3_625, idle: 2) == false)
        #expect(session.startedAt == nil)
    }

    @Test func deckRotatesLayoutsAndRestoresItsCursor() {
        var deck = PromptDeck()
        var prompts: [Prompt] = []
        for index in 0..<104 {
            let prompt = deck.draw()
            #expect(prompt.kind == PromptKind.allCases[index % 4])
            prompts.append(prompt)
        }
        #expect(Set(prompts.map(\.title)).count == 104)
        for kind in PromptKind.allCases {
            for tone in PromptTone.allCases {
                #expect(prompts.filter { $0.kind == kind && $0.tone == tone }.count == 13)
            }
        }
        let firstPass = Array(prompts.prefix(8))
        #expect(firstPass.filter { $0.tone == .coach }.count == 4)
        #expect(firstPass.first?.tone != firstPass.dropFirst(4).first?.tone)
        #expect(deck.draw().kind == .question)
        var restored = PromptDeck(order: deck.order, cursor: deck.cursor)
        #expect(restored.draw() == deck.draw())
    }

    @Test func upgradingFromTheFiftyTwoCardDeckStartsTheExpandedDeck() {
        let oldOrder = (0..<13).flatMap { index in (0..<4).map { $0 * 13 + index } }
        var deck = PromptDeck(order: oldOrder, cursor: 37)
        #expect(deck.order.count == 104)
        #expect(deck.cursor == 0)
        let firstTwo = (0..<2).map { _ in deck.draw() }
        #expect(firstTwo.map(\.tone) == [.gentle, .coach])
    }

    @Test func coachOnlyDeckRotatesLayoutsAndRestoresItsCursor() {
        var deck = PromptDeck(tone: .coach)
        let firstPass = (0..<52).map { _ in deck.draw() }
        #expect(firstPass.allSatisfy { $0.tone == .coach })
        #expect(Set(firstPass.map(\.title)).count == 52)
        #expect(firstPass.enumerated().allSatisfy { index, prompt in
            prompt.kind == PromptKind.allCases[index % 4]
        })
        let firstOfNextPass = deck.draw()
        #expect(firstOfNextPass.tone == .coach && firstOfNextPass.kind == .question)
        var restored = PromptDeck(order: deck.order, cursor: deck.cursor, tone: .coach)
        let expected = deck.draw()
        let actual = restored.draw()
        #expect(actual == expected)
        #expect(actual.tone == .coach)
    }
}
