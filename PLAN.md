# Waymark implementation plan

Waymark is a local macOS menu-bar utility for noticing when laptop use has drifted. A check-in gives the person a chance to continue deliberately, take a break, or make a concrete change.

## Timing and activity

Start from fresh keyboard, pointer, or scroll input while the display and user session are active. Sample system idle times every two seconds and use a monotonic clock. A gap in sampling longer than eight seconds invalidates the session.

| What the Mac reports | First automatic check-in | Follow-up |
| --- | --- | --- |
| Ordinary interaction, including scroll-only use | After 10 full minutes, on fresh input | 20 minutes, on fresh input |
| Frequent keys or clicks across at least eight samples in a minute | After 15 full minutes, on fresh input | 30 minutes, on fresh input |
| Sustained low input and a system-wide indication that software is keeping the display awake | After 40 full minutes without input | One per input-free stretch |
| No input and no display-awake evidence | End the session after the chosen idle gap | Start over on fresh input |

The default idle gap is three minutes, with 90-second and five-minute options. Fresh input for interactive prompts means a new event after the deadline, observed within five seconds. An isolated action during likely viewing extends the viewing interval. Repeated input or the end of the display-awake signal brings back interactive timing. Keyboard and click frequency guide pacing. They cannot determine whether someone is working.

The passive path is the only automatic presentation that can occur without an immediate input event. It requires a previously started session and an active display-awake assertion. The signal can miss video or reflect other software keeping the display on. Lock, screen saver, display sleep, system sleep, console switch, invalid readings and long polling gaps invalidate the session.

## Check-in states

| State or action | Behavior |
| --- | --- |
| Delivery | Show one card and set a follow-up deadline using the current pace. |
| Acknowledge or dismiss | Ask for at least three words naming the next action. Confirming closes the card and anchors the regular follow-up. |
| Five more minutes | Ask what those minutes are for before snoozing. Allow two snoozes per continuous session. |
| Leave waiting | Tuck an unfinished reflection into the menu bar and discard its text. The regular schedule continues. |
| Ignored for 30 seconds | Tuck the card into the menu bar. The regular schedule continues. |
| Open check-in | Reopen the same card with keyboard focus when requested. |
| Choose a next move | Offer four concrete moves. Keep the choice in memory and show it at the next check-in in the same session. |
| Start 1-minute timer | Keep the experiment text visible beside a silent 60-second countdown, then offer a return or refocus. |
| Take a reset | Run a voluntary 30-second timer, then offer a return or refocus. |
| Quiet mode | Pause for an hour and clear session state. Resume and expiry require a fresh session. |
| Session ends | Drop pending cards, deadlines, snooze count, and selected next move. |

## Design and privacy

A silent, roughly 465-point floating card appears in the upper-right safe area of the pointer display. Automatic cards do not take key focus. Explicitly opened cards can receive keyboard input. The card uses static presentation with no animation or flashing and can announce its arrival through VoiceOver. Floating cards support auxiliary full-screen Spaces. Capture exclusion is best effort. Quiet mode is available before presenting or sharing a screen.

The 104-card shuffled deck interleaves four formats and two tones. There are 13 gentle and 13 blunt coach prompts per format. The question uses an editorial callout, the fork gives two distinct choices, the one-minute experiment offers a small action, and the reset prompts a brief physical pause. Coach cards use heavier headlines and can include profanity.

When an automatic check-in is due and either the hardware or session scroll event is at most 10 seconds old, select from a separate shuffled rotation of the 52 coach cards. Preserve both deck positions in UserDefaults. Use recent scrolling to pick the tone and existing activity rules to schedule delivery.

The menu-bar and Settings preview controls share a separate in-memory deck. Each click advances the preview, including the **Next preview** button on the card itself.

Waymark samples elapsed time and aggregate numeric counts for selected event types. It reads the system-wide display-awake flag. It never reads system-wide key values, target windows, app identity, browser history, or media content. The reflection field validates its own text in memory and discards it when the card closes. UserDefaults stores the idle choice, first-open flag, and deck shuffle state. The app has no telemetry or network dependencies.

## Engineering and shipping

- `ActivitySession.swift` owns timing and transitions. `Prompt.swift` owns content and deck order.
- `ActivityMonitor.swift` samples Core Graphics event ages and counter deltas, IOKit’s aggregate display assertion, and workspace lifecycle notifications.
- `WaymarkApp.swift` coordinates the status menu, panel, timers, and in-memory state. `CardPanel.swift`, `CheckInView.swift`, and `SettingsView.swift` handle the native presentation.
- Pure tests cover gate boundaries, input pacing, idle and passive transitions, snoozes, quiet mode, and deck order. Live checks cover opening the bundle, layout and actions, and the desktop activity interface.
- Ship an ad-hoc signed local bundle and Swift package. Login registration is opt-in using SMAppService. Updates use manual bundle replacement. Developer ID signing and notarization are separate distribution work.

## Claude Opus review

Claude Opus 5.5 confirmed the original revised plan was ready for local implementation. The review added the timeout and reopen behavior, snooze cap, next-move choice, 52-prompt deck, and VoiceOver announcement. When the activity rules changed, Opus identified a conflict between the original fresh-input gate and video viewing. We agreed to let the 40-minute passive check-in use the display-awake signal so it can appear without fresh input.
