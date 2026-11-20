# Project updates

## 0.1.3 · 20 November 2026

- Added a coach-only rotation for automatic reminders that come due within 10 seconds of a scroll event.
- Kept separate shuffle positions for scrolling and regular reminders so scrolling can cycle through all 52 coach cards.
- Passed all 14 automated tests and verified the signature inside the ZIP. Real mouse-wheel and trackpad routing were not exercised live for this build.

## 0.1.2 · 20 November 2026

- Added 52 blunt coach prompts across the four layouts, bringing the deck to 104. The expanded deck starts a fresh shuffle when it reads saved 52-card state.
- Added a three-word reflection before finishing or snoozing a fresh check-in. Unfinished check-ins can wait in the menu bar, and reflection text is discarded on close.
- Passed 13 automated tests, including the expanded deck and upgrade from saved 52-card state. Verified the signed ZIP and rendered both the coach card and reflection layout. Live keyboard entry remains unverified.

## 0.1.1 · 20 November 2026

- Made **Preview a check-in** advance a shuffled preview deck instead of reusing the first card of a format. Each click rotates to a different format.
- Added **Next preview** to the card and connected the Settings button to the same deck. Previews leave the automatic schedule and saved deck position in place.
- Added a visible 60-second experiment countdown alongside the existing 30-second reset.
- Renamed the idle setting to **Reset after no input for** and explained when it applies.
- Passed the 12 automated tests, verified the signed ZIP, and rendered the experiment’s start, countdown and completion views. The menu-bar interactions were not exercised live for this release.

## 0.1.0 · 19 November 2026

- Reviewed the plan and revised activity rules with Claude Opus 5.5 in the Claude desktop app.
- Implemented the native menu-bar utility, 52 prompts in four formats, and the refocus, snooze, reset and quiet flows.
- Added explicit scroll activity, a higher-input cadence and a bounded passive-viewing cadence using the system-wide display-awake flag.
- Verified 12 automated checks on Apple silicon, covering timing boundaries, quiet mode, lifecycle gates, passive viewing, and deck rotation.
- Rendered and inspected all four card layouts, the refocus panel and the reset countdown using the shipping SwiftUI views.
- Verified the bundle’s signature, icon, Apple silicon executable and ZIP integrity. The desktop automation attempts expired before a live launch could be inspected. A direct command-line smoke test reached AppKit and was blocked at GUI application registration in the shell sandbox.
- Live follow-up checks are macOS menu-bar launch, real scroll-only hardware input, card focus, VoiceOver, Spaces and multiple displays, and opt-in login registration. Use the built-in previews for the visual and interaction checks.
