public enum PromptKind: String, CaseIterable, Sendable {
    case question, fork, experiment, reset
}

public enum PromptTone: CaseIterable, Sendable {
    case gentle, coach
}

public struct Prompt: Sendable, Equatable {
    public let kind: PromptKind
    public let tone: PromptTone
    public let title: String
    public let detail: String

    public static let catalog: [Prompt] =
        make(.question, [
            ("Did you mean to still be here?", "A quick gut check. If the answer is yes, carry on."),
            ("What brought you here?", "See if what you’re doing still matches the reason you opened your Mac."),
            ("Would you choose this again?", "Imagine you just sat down. Would you open the same thing?"),
            ("Is this giving you what you came for?", "You can finish up as soon as you have enough."),
            ("Where did your attention go?", "Say it in a few words. Then decide if you want to leave it there."),
            ("What are you waiting for?", "If you’re hoping the next click will feel different, a change of scene might help."),
            ("Is there a good stopping point nearby?", "Pick one you’ll recognize when you reach it."),
            ("Are you getting a real break?", "If this still feels restful, enjoy it. If you feel restless, you can change activities."),
            ("What made you open that last tab?", "Notice whether there’s something you want from it."),
            ("Have you found enough to move forward?", "If you have an answer you can use, try putting it to work."),
            ("What would make this time well spent?", "Choose an answer that fits today."),
            ("Are you still curious?", "If the curiosity has gone, you can leave the rest for another time."),
            ("What deserves your next click?", "Give yourself a moment to make that choice.")
        ]) +
        make(.fork, [
            ("Stay here or change course?", "Keep going deliberately, or choose a different next move."),
            ("Finish this or set it aside?", "Decide how much of the current thing needs your time."),
            ("Follow this thread or return to the first one?", "Either is a choice you can make on purpose."),
            ("Read one more or call it enough?", "You get to decide when you have what you need."),
            ("Keep resting or try a different break?", "Notice which option sounds more refreshing."),
            ("Keep exploring or make something with what you found?", "Use the next few minutes for whichever you need more."),
            ("Stay in the conversation or come back later?", "You can leave time for a more considered reply."),
            ("Open another tab or work with this one?", "Think of the question you actually want answered."),
            ("Polish a detail or get the rough version done?", "Choose based on what would help you move forward."),
            ("Continue watching or save your place?", "If you want to stop soon, pick a clear ending."),
            ("Keep browsing or make the decision?", "Ask whether more options are likely to help."),
            ("Do this now or put it on your list?", "Some things are easier to leave once you’ve written them down."),
            ("Respond now or give it some space?", "Choose how much attention you want to give this.")
        ]) +
        make(.experiment, [
            ("Give the next step one minute.", "Do the smallest useful piece. Stop after a minute if that’s enough."),
            ("Make a rough start.", "Write one messy line of the thing you’ve been avoiding."),
            ("Close one tab you’ve finished with.", "See if the screen feels easier to return to."),
            ("Give one window your attention.", "See what changes when you leave the others alone for a minute."),
            ("Write down the question.", "Before you search again, put what you want to find into one sentence."),
            ("Pick the next stopping point.", "Use the end of this page, video, or task as a place to check in again."),
            ("Find the part you can do now.", "Choose one piece you can start with what you already have."),
            ("Leave a note for when you come back.", "One line about where you left off can make it easier to step away."),
            ("Try doing one thing all the way through.", "Choose something short enough to finish in the next minute."),
            ("Put one distraction aside.", "Move it out of view for a minute and see where your attention lands."),
            ("Look at what you already have.", "Spend a minute with your current notes before looking for more."),
            ("Name what’s making this hard to start.", "See if one small change would make the first step easier."),
            ("Choose when to return.", "If this can wait, give it a particular time so you can let it go for now.")
        ]) +
        make(.reset, [
            ("Give your eyes some distance.", "Look at something across the room for a few seconds."),
            ("Let your shoulders settle.", "Move them gently, then let your hands rest."),
            ("Find a spot beyond the screen.", "A window, a wall, anything that lets your gaze go farther."),
            ("Let the next click wait.", "Put your hands in your lap and take a moment before coming back."),
            ("Give your hands a break.", "Rest them in whatever position feels comfortable."),
            ("Take a sip if you have a drink nearby.", "Leave the next tab until you’ve put the cup down."),
            ("Change how you’re sitting.", "Find a position that feels a little easier."),
            ("Turn to look around the room.", "Give yourself a few seconds to notice something beyond the display."),
            ("Settle your feet.", "Notice where you feel supported before returning to the screen."),
            ("Step back if you feel like it.", "You can take half a minute away from the desk."),
            ("Blink and look up.", "Pick something farther away and let your eyes rest there."),
            ("Give yourself a quiet pause.", "Leave things open and come back to the same spot when you’re ready."),
            ("Notice one sound in the room.", "Give it a moment of attention before deciding what to do next.")
        ]) +
        make(.question, tone: .coach, [
            ("What the fuck are you really doing?", "Name it in plain words. Would you choose to spend another five minutes on it?"),
            ("Where the hell did the last ten minutes go?", "Name what you got out of them. Then decide what earns the next ten."),
            ("What are you avoiding right now?", "Say the task out loud. Open the part you’ve been dodging."),
            ("Would you call this a real break?", "Check how you feel. If you’re more wired than before, get off the screen."),
            ("Why did you open this laptop?", "Answer before you touch another tab."),
            ("How many times are you going to reload this?", "Name the actual update you’re waiting for. Decide when to check again."),
            ("What does another five minutes buy you?", "Name the damn payoff. Decide if it’s worth five minutes."),
            ("Have you played the hard part yet?", "Find the bar you keep skipping. Start there."),
            ("When exactly are you stopping?", "Pick an ending you’ll recognize when you hit it."),
            ("What’s your excuse for one more?", "Say it out loud. See if you buy it."),
            ("Who picked the next click, you or the feed?", "Take your hand off the trackpad and make the choice yourself."),
            ("What have you actually finished?", "Point to one concrete thing. If you’re stuck, name the smallest piece you can finish."),
            ("Does this shit deserve your attention?", "Give it a straight answer before you scroll again.")
        ]) +
        make(.fork, tone: .coach, [
            ("Pick a damn lane.", "Stay and finish this, or close it and give the other thing your attention."),
            ("Play the hard bar or call it.", "Give the rough bit one honest attempt, or decide when you’ll come back."),
            ("Keep watching or kill the autoplay.", "If you want the next video, choose it yourself."),
            ("Send it or schedule the reply.", "This draft has had enough laps. Decide when it goes out."),
            ("Take the break for real.", "Stay because this feels good, or shut the lid and do something that does."),
            ("Make the call or name what’s missing.", "If you need more information, name the exact thing before another search."),
            ("Ship the rough thing or set a finish line.", "Decide what actually needs fixing before you touch it again."),
            ("Open the task or admit you’re putting it off.", "Either start now or give it a real time on the calendar."),
            ("Keep the tab or cut it loose.", "Say what it’s for. If you can’t, close the damn thing."),
            ("Do the rep or end the session.", "Pick one clean attempt you can make right now."),
            ("Read the whole thing or get out.", "Decide whether this is worth your full attention."),
            ("Use what you found or stop digging.", "Put one result to work, or close the search for now."),
            ("Finish the job or take an actual break.", "Choose the next move before the next click makes it for you.")
        ]) +
        make(.experiment, tone: .coach, [
            ("Write the damn first line.", "Sixty seconds. Make it ugly enough to start."),
            ("Play the worst bar once.", "Go slowly. Find the exact place it falls apart."),
            ("Close the tab you keep crawling back to.", "Spend the next minute inside the thing you opened your Mac to do."),
            ("Stop circling it. Start.", "Set the timer and work on the smallest piece you can touch right now."),
            ("Put one ugly version on the page.", "You can fix it after the timer. Get something down first."),
            ("Get the actual question on paper.", "Write one sentence before you spend another minute searching."),
            ("Mark the exact point you got stuck.", "Pick one thing to try differently on the next pass."),
            ("Hit record and take the damn run.", "Use one minute to make a first pass you can review later."),
            ("Close two tabs. Get back to it.", "Give the active task the whole minute."),
            ("Do the boring bit you keep dodging.", "Start with the first sixty seconds of it."),
            ("Make one decision you’ve been dragging out.", "Pick from what you have. Write down what you picked."),
            ("Finish one damn thing.", "Choose a piece you can actually finish before the timer hits zero."),
            ("Try the hard bit at half speed.", "One minute, one attempted fix. See what changes.")
        ]) +
        make(.reset, tone: .coach, [
            ("Hands off the damn trackpad.", "Rest your hands for thirty seconds. The tab can wait."),
            ("Look up. The screen has had enough.", "Pick something across the room and let your eyes settle there."),
            ("Stop feeding the next click.", "Let the urge pass before you move your hand again."),
            ("Drop your damn shoulders.", "Let them settle, then unclench your hands."),
            ("Take an actual thirty-second break.", "Look away from the screen. Leave your phone where it is."),
            ("Get your eyes off the feed.", "Look at the farthest thing you can see for a few seconds."),
            ("Step back from the desk.", "Move away if it’s comfortable. Decide what to do before you sit back down."),
            ("Quit chasing the next hit.", "Put your hands on your lap and let thirty seconds go by."),
            ("Let the damn video sit there.", "Pause it for half a minute. Decide whether you want to press play again."),
            ("Stop scrolling long enough to blink.", "Look up, blink a few times, and let the next swipe wait."),
            ("Put the screen down for a beat.", "Take a sip or look around the room before touching it again."),
            ("Get out of that hunched position.", "Find a more comfortable posture before you continue."),
            ("Give it thirty seconds of silence.", "Let your hands rest and listen to the room before choosing your next move.")
        ])

    private static func make(_ kind: PromptKind, tone: PromptTone = .gentle, _ entries: [(String, String)]) -> [Prompt] {
        entries.map { Prompt(kind: kind, tone: tone, title: $0.0, detail: $0.1) }
    }
}

public struct PromptDeck {
    private static let mixedSlots: [(kind: PromptKind, tone: PromptTone)] = [
        (.question, .gentle), (.fork, .coach), (.experiment, .gentle), (.reset, .coach),
        (.question, .coach), (.fork, .gentle), (.experiment, .coach), (.reset, .gentle)
    ]

    private let groups: [[Int]]
    public private(set) var order: [Int]
    public private(set) var cursor: Int

    public init(order: [Int] = [], cursor: Int = 0, tone: PromptTone? = nil) {
        let slots = tone.map { tone in
            PromptKind.allCases.map { (kind: $0, tone: tone) }
        } ?? Self.mixedSlots
        let catalog = Prompt.catalog
        let groups = slots.map { slot in
            catalog.indices.filter { catalog[$0].kind == slot.kind && catalog[$0].tone == slot.tone }
        }
        self.groups = groups
        if Self.isValid(order, groups: groups), (0...order.count).contains(cursor) {
            self.order = order
            self.cursor = cursor
        } else {
            self.order = Self.shuffledOrder(groups)
            self.cursor = 0
        }
    }

    public mutating func draw() -> Prompt {
        if cursor == order.count {
            order = Self.shuffledOrder(groups)
            cursor = 0
        }
        defer { cursor += 1 }
        return Prompt.catalog[order[cursor]]
    }

    private static func isValid(_ order: [Int], groups: [[Int]]) -> Bool {
        let eligible = groups.flatMap { $0 }
        guard order.count == eligible.count, Set(order) == Set(eligible) else { return false }
        return order.enumerated().allSatisfy { position, index in
            groups[position % groups.count].contains(index)
        }
    }

    private static func shuffledOrder(_ groups: [[Int]]) -> [Int] {
        let shuffled = groups.map { $0.shuffled() }
        return shuffled[0].indices.flatMap { position in
            shuffled.map { $0[position] }
        }
    }
}
