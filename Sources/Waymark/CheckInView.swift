import SwiftUI
import WaymarkCore

enum NextMove: String, CaseIterable {
    case returnToTask = "Return to my main task"
    case closeDistraction = "Close what’s distracting me"
    case finishOne = "Finish one small thing"
    case takeBreak = "Step away from the screen"

    var symbol: String {
        switch self {
        case .returnToTask: "arrow.uturn.left"
        case .closeDistraction: "rectangle.portrait.and.arrow.right"
        case .finishOne: "checkmark"
        case .takeBreak: "leaf"
        }
    }
}

struct CheckIn {
    enum Stage {
        case prompt, reflect(Dismissal), refocus, timing(CardTimer, until: TimeInterval), finished(CardTimer)
    }

    var prompt: Prompt
    var preview = false
    var stage: Stage = .prompt
}

enum Dismissal: Equatable {
    case finish, snooze
}

enum CardTimer: Equatable {
    case experiment, reset

    var duration: TimeInterval { self == .experiment ? 60 : 30 }
}

enum CardAction {
    case stay, snooze, dismiss, confirmDismissal, refocus, back, startTimer(CardTimer), pick(NextMove), nextPreview
}

private struct CardPalette {
    let paper: Color
    let ink: Color
    let accent: Color

    init(_ kind: PromptKind) {
        switch kind {
        case .question:
            paper = Color(red: 0.956, green: 0.946, blue: 0.900)
            ink = Color(red: 0.091, green: 0.207, blue: 0.167)
            accent = Color(red: 0.267, green: 0.388, blue: 0.301)
        case .fork:
            paper = Color(red: 0.978, green: 0.899, blue: 0.836)
            ink = Color(red: 0.271, green: 0.174, blue: 0.128)
            accent = Color(red: 0.512, green: 0.296, blue: 0.230)
        case .experiment:
            paper = Color(red: 0.918, green: 0.905, blue: 0.972)
            ink = Color(red: 0.211, green: 0.163, blue: 0.331)
            accent = Color(red: 0.371, green: 0.286, blue: 0.540)
        case .reset:
            paper = Color(red: 0.878, green: 0.940, blue: 0.891)
            ink = Color(red: 0.091, green: 0.239, blue: 0.205)
            accent = Color(red: 0.231, green: 0.396, blue: 0.321)
        }
    }
}

struct CheckInView: View {
    let card: CheckIn
    let minutes: Int
    let intention: NextMove?
    let canSnooze: Bool
    let width: CGFloat
    let act: (CardAction) -> Void

    private typealias TextState = State<String>
    @TextState private var nextAction = ""
    @FocusState private var nextActionFocused: Bool

    private var palette: CardPalette { CardPalette(card.prompt.kind) }
    private var isCoach: Bool { card.prompt.tone == .coach }
    private var isReflecting: Bool {
        if case .reflect = card.stage { return true }
        return false
    }
    private var canConfirmDismissal: Bool {
        nextAction.split(whereSeparator: \.isWhitespace)
            .filter { $0.contains(where: \.isLetter) }.count >= 3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            header
            switch card.stage {
            case .prompt: promptBody
            case .reflect(let dismissal): reflectionBody(dismissal)
            case .refocus: refocusBody
            case .timing(let timer, let end): timerBody(timer, endsAt: end)
            case .finished(let timer): finishedBody(timer)
            }
        }
        .padding(22)
        .frame(width: width, alignment: .leading)
        .foregroundStyle(palette.ink)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(palette.paper)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(palette.ink.opacity(0.16), lineWidth: 1)
                }
        }
        .environment(\.colorScheme, .light)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var header: some View {
        HStack(spacing: 7) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 8))
                .accessibilityHidden(true)
            Text(headerTitle)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(1.2)
            Spacer()
            if card.preview {
                quietButton("Next preview", .nextPreview)
            } else {
                Text("\(minutes) min this session")
                    .font(.system(size: 11, weight: .medium))
            }
            if !isReflecting {
                Button {
                    act(.dismiss)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 24, height: 24)
                        .background(palette.ink.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close check-in")
                .keyboardShortcut(.cancelAction)
            }
        }
        .foregroundStyle(isCoach ? Color(red: 0.51, green: 0.25, blue: 0.15) : palette.accent)
    }

    private var headerTitle: String {
        let label = isCoach ? "COACH" : "WAYMARK"
        return card.preview ? "\(label) PREVIEW" : label
    }

    private func reflectionBody(_ dismissal: Dismissal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            headline(dismissal == .snooze ? "What are the next five minutes for?" : "What will you do next?", size: 29)
            detail("Put the next thing you’ll actually do into at least three words.")
            TextField("E.g. Open my draft", text: $nextAction)
                .accessibilityLabel("Your next action")
                .textFieldStyle(.roundedBorder)
                .controlSize(.large)
                .focused($nextActionFocused)
                .onAppear { nextActionFocused = true }
                .onSubmit {
                    if canConfirmDismissal { act(.confirmDismissal) }
                }
            HStack(spacing: 10) {
                actionButton(dismissal == .snooze ? "Snooze 5 min" : "Finish check-in", primary: true, .confirmDismissal)
                    .disabled(!canConfirmDismissal)
                quietButton("Back to check-in", .back)
                Spacer()
                quietButton(card.preview ? "Close preview" : "Leave waiting", .dismiss)
                    .keyboardShortcut(.cancelAction)
            }
        }
    }

    @ViewBuilder private var promptBody: some View {
        if let intention {
            Label(intention.rawValue, systemImage: intention.symbol)
                .font(.system(size: 12, weight: .semibold))
                .accessibilityLabel("Your next move was: \(intention.rawValue)")
        }

        switch card.prompt.kind {
        case .question:
            VStack(alignment: .leading, spacing: 8) {
                headline(card.prompt.title, size: 32)
                detail(card.prompt.detail)
            }
            .padding(.leading, 13)
            .overlay(alignment: .leading) {
                Capsule().fill(palette.accent.opacity(0.58)).frame(width: 2)
                    .accessibilityHidden(true)
            }
            HStack(spacing: 8) {
                actionButton("I’m on track", primary: true, .stay)
                actionButton("Choose a next move", .refocus)
            }

        case .fork:
            headline(card.prompt.title, size: 28)
            detail(card.prompt.detail)
            HStack(spacing: 9) {
                fork("Stay here", symbol: "arrow.forward", action: .stay)
                fork("Change course", symbol: "arrow.turn.down.right", action: .refocus)
            }

        case .experiment:
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 2) {
                    Text("01").font(.system(size: 28, weight: .medium, design: .monospaced))
                    Text("MIN").font(.system(size: 9, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(palette.accent)
                .frame(width: 66, height: 67)
                .background(palette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                .accessibilityLabel("One minute experiment")
                VStack(alignment: .leading, spacing: 7) {
                    headline(card.prompt.title, size: 27)
                    detail(card.prompt.detail)
                }
            }
            HStack(spacing: 8) {
                actionButton("Start 1-minute timer", primary: true, .startTimer(.experiment))
                actionButton("Choose a next move", .refocus)
            }

        case .reset:
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    headline(card.prompt.title, size: 29)
                    detail(card.prompt.detail)
                }
                Spacer(minLength: 0)
                ResetMark()
                    .stroke(palette.accent.opacity(0.32), lineWidth: 1)
                    .frame(width: 58, height: 65)
                    .accessibilityHidden(true)
            }
            HStack(spacing: 8) {
                actionButton("Take 30 seconds", primary: true, .startTimer(.reset))
                actionButton("I’m on track", .stay)
            }
        }

        HStack(spacing: 14) {
            if card.prompt.kind != .reset {
                quietButton("Take a reset", .startTimer(.reset))
            } else {
                quietButton("Choose a next move", .refocus)
            }
            Spacer(minLength: 5)
            if canSnooze {
                quietButton("5 more min", .snooze)
            }
        }
    }

    private var refocusBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            headline("What’s your next move?", size: 28)
            detail(card.preview ? "Pick one to try the flow." : "Pick one to see it at your next check-in.")
            ForEach(NextMove.allCases, id: \.self) { move in
                Button {
                    act(.pick(move))
                } label: {
                    HStack {
                        Label(move.rawValue, systemImage: move.symbol)
                        Spacer()
                        Image(systemName: "arrow.right").accessibilityHidden(true)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background(palette.ink.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            quietButton("Back to check-in", .back)
        }
    }

    private func timerBody(_ timer: CardTimer, endsAt: TimeInterval) -> some View {
        HStack(spacing: 17) {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                let seconds = max(0, Int(ceil(endsAt - WaymarkTime.now)))
                ZStack {
                    Circle().stroke(palette.ink.opacity(0.12), lineWidth: 3)
                    Circle().trim(from: 0, to: min(Double(seconds) / timer.duration, 1))
                        .stroke(palette.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                        .font(.system(size: 21, weight: .medium, design: .monospaced))
                }
                .frame(width: 72, height: 72)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(seconds) seconds remaining")
            }
            VStack(alignment: .leading, spacing: 8) {
                if timer == .experiment {
                    headline(card.prompt.title, size: 27)
                    detail(card.prompt.detail)
                    quietButton("End timer", .stay)
                } else {
                    headline("A little room to reset.", size: 27)
                    detail("Look away or stretch gently. Come back whenever you’re ready.")
                    quietButton("End reset", .stay)
                }
            }
        }
        .padding(.vertical, 5)
    }

    private func finishedBody(_ timer: CardTimer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            headline(timer == .experiment ? "How did that go?" : "What feels right now?", size: 29)
            detail(timer == .experiment
                   ? "Keep going if this is helping, or pick a different next move."
                   : "Return to what you were doing or pick a different direction.")
            HStack(spacing: 8) {
                actionButton(timer == .experiment ? "Keep going" : "I’m ready", primary: true, .stay)
                actionButton("Choose a next move", .refocus)
            }
        }
    }

    private func headline(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: isCoach ? .semibold : .regular, design: .serif))
            .lineSpacing(1)
            .accessibilityAddTraits(.isHeader)
    }

    private func detail(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(palette.ink.opacity(0.89))
            .lineSpacing(2)
    }

    private func actionButton(_ label: String, primary: Bool = false, _ action: CardAction) -> some View {
        Button {
            act(action)
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
        }
        .buttonStyle(CardButtonStyle(
            foreground: primary ? palette.paper : palette.ink,
            background: primary ? palette.ink : palette.ink.opacity(0.09)
        ))
    }

    private func quietButton(_ label: String, _ action: CardAction) -> some View {
        Button {
            act(action)
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .padding(.vertical, 4)
                .foregroundStyle(palette.accent)
        }
        .buttonStyle(.plain)
    }

    private func fork(_ label: String, symbol: String, action: CardAction) -> some View {
        Button {
            act(action)
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: symbol).accessibilityHidden(true)
                Text(label)
                Spacer(minLength: 0)
            }
            .font(.system(size: 12, weight: .semibold))
            .padding(11)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(CardButtonStyle(foreground: palette.ink, background: palette.ink.opacity(0.09)))
    }
}

private struct CardButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let foreground: Color
    let background: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: 8))
            .opacity(isEnabled ? (configuration.isPressed ? 0.68 : 1) : 0.45)
    }
}

private struct ResetMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for inset in [0.0, 7.0, 14.0, 21.0] {
            let loop = rect.insetBy(dx: inset, dy: inset)
            path.addEllipse(in: loop)
        }
        return path
    }
}
